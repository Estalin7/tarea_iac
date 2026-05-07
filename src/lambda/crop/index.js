"use strict";

const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");

const s3 = new S3Client({ region: process.env.AWS_REGION || "us-east-1" });
const SIZE = 40;

async function getS3Object(key) {
  const { Body } = await s3.send(new GetObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key:    key,
  }));
  const chunks = [];
  for await (const chunk of Body) chunks.push(chunk);
  return Buffer.concat(chunks);
}

async function cropCircular(inputBuffer) {
  const mask = Buffer.from(
    `<svg width="${SIZE}" height="${SIZE}">
       <circle cx="${SIZE/2}" cy="${SIZE/2}" r="${SIZE/2}" fill="white"/>
     </svg>`
  );

  return sharp(inputBuffer)
    .resize(SIZE, SIZE, { fit: "cover", position: "centre" })
    .composite([{ input: mask, blend: "dest-in" }])
    .png({ compressionLevel: 9 })
    .toBuffer();
}

exports.handler = async (event) => {
  const failures = [];

  for (const sqsRecord of event.Records) {
    try {
      const body = JSON.parse(sqsRecord.body);

      if (!body.Records) { console.warn("Formato inesperado:", sqsRecord.messageId); continue; }

      for (const s3Record of body.Records) {
        if (!s3Record.eventName?.startsWith("ObjectCreated")) continue;

        const sourceKey = decodeURIComponent(s3Record.s3.object.key.replace(/\+/g, " "));
        const baseName  = sourceKey.split("/").pop().replace(/\.[^.]+$/, "");
        const destKey   = `${process.env.PROCESSED_PREFIX}/${baseName}_circular.png`;

        const inputBuffer  = await getS3Object(sourceKey);
        const outputBuffer = await cropCircular(inputBuffer);

        await s3.send(new PutObjectCommand({
          Bucket:      process.env.S3_BUCKET,
          Key:         destKey,
          Body:        outputBuffer,
          ContentType: "image/png",
          Metadata: {
            sourceKey,
            processedAt: new Date().toISOString(),
            size:        `${SIZE}x${SIZE}`,
          },
        }));

        console.log(`Procesado: ${destKey} (${outputBuffer.length} bytes)`);
      }
    } catch (err) {
      console.error(`Error en mensaje ${sqsRecord.messageId}:`, err);
      failures.push({ itemIdentifier: sqsRecord.messageId });
    }
  }

  return { 
    batchItemFailures: failures 
    };
};
