"use strict";

const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const busboy = require("busboy");
const { v4: uuidv4 } = require("uuid");

const s3 = new S3Client({ region: process.env.AWS_REGION || "us-east-1" });

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"];

const MAX_SIZE = 10 * 1024 * 1024;

const EXT_MAP  = { 
    "image/jpeg": "jpg",
     "image/png": "png", 
     "image/gif": "gif", 
     "image/webp": "webp",
     };

function parseMultipart(event) {
  return new Promise((resolve, reject) => {
    const contentType = event.headers?.["content-type"] || event.headers?.["Content-Type"] || "";
    const bb = busboy({ headers: { "content-type": contentType }, limits: { fileSize: MAX_SIZE } });

    let fileBuffer = null, mimeType = null, filename = null;

    bb.on("file", (field, file, info) => {
      mimeType = info.mimeType;
      filename = info.filename;
      const chunks = [];
      file.on("data", c => chunks.push(c));
      file.on("limit", () => reject(new Error("Archivo mayor a 10 MB")));
      file.on("end",  () => { fileBuffer = Buffer.concat(chunks); });
    });

    bb.on("finish", () => resolve({ fileBuffer, mimeType, filename }));
    bb.on("error", reject);

    const body = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body || "");

    bb.write(body);
    bb.end();
  });
}

function parseJson(event) {
  const body = JSON.parse(event.body);
  if (!body.image) throw new Error("Falta el campo 'image' en el body JSON");
  return {
    fileBuffer: Buffer.from(body.image, "base64"),
    mimeType:   body.mimeType || "image/jpeg",
    filename:   body.filename || "upload",
  };
}

exports.handler = async (event) => {
  try {
    const ct = (event.headers?.["content-type"] || event.headers?.["Content-Type"] || "").toLowerCase();

    let fileBuffer;
    let mimeType;
    let filename;

    if (ct.includes("multipart/form-data")) {
      ({ fileBuffer, mimeType, filename } = await parseMultipart(event));

    } else if (ct.includes("application/json")) {
      ({ fileBuffer, mimeType, filename } = parseJson(event));

    } else {
      return res(415, { error: "Content-Type no soportado. Usa multipart/form-data o application/json" });
    }

    if (!fileBuffer || fileBuffer.length === 0) 

        return res(400, { error: "Archivo vacío" });

    if (fileBuffer.length > MAX_SIZE)          

          return res(413, { error: "Archivo mayor a 10 MB" });

    if (!ALLOWED_TYPES.includes(mimeType))   

        return res(400, { error: `Tipo no permitido: ${mimeType}` });

    const imageId = uuidv4();
    const key     = `${process.env.UPLOAD_PREFIX}/${imageId}.${EXT_MAP[mimeType]}`;

    await s3.send(new PutObjectCommand({
      Bucket:      process.env.S3_BUCKET,
      Key:         key,
      Body:        fileBuffer,
      ContentType: mimeType,
      Metadata: {
        originalFilename: filename || "unknown",
        uploadedAt:       new Date().toISOString(),
      },
    }));

    console.log(`Subido: ${key} (${fileBuffer.length} bytes)`);
    return res(200, { message: "Imagen subida correctamente", 
        imageId,
         key, 
         size: fileBuffer.length 
        }
    );

  } catch (err) {
    console.error("Error:", err);
    return res(500, { error: "Error interno", detail: err.message });
  }
};

function res(statusCode, body) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    body: JSON.stringify(body),
  };
}