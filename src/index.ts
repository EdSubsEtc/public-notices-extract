


const PUBLIC_NOTICE_EXTRACT_WEB_HOOK_URL = process.env.WEB_HOOK_URL || "https://chat.googleapis.com/v1/spaces/AAAAFIcw4FE/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=saT5iu2zFrfWfiPzMy4wFkEw-gZUpxfXxp8Yrk3HoqU";

import { getPublicNoticesByDate, PnPData } from './gemstone';
import { Storage } from '@google-cloud/storage';

async function main() {

  console.log("started");

  const date = new Date();
  date.setHours(0, 0, 0, 0);

  const publicNotices = await getPublicNoticesByDate(date);

  let fileSendCompletion = sendToBucket(publicNotices, date);

  let msg: any = {};

  if (PUBLIC_NOTICE_EXTRACT_WEB_HOOK_URL.includes("chat.googleapis.com")) {

    console.log("Testing to Google Chat Web Hook, formatting payload as text message, only first 10 records");

    const firstTen = publicNotices.slice(0, 10);
    const asString = JSON.stringify(firstTen, null, 2);

    msg.text = JSON.stringify({ public_notices: firstTen }, null, 2);

  } else {
    console.log("Formatting payload for Make.com Public Notice Processor Web Hook");
    msg = {
      public_notices: publicNotices
    };
  }

  const webHookResponse = await
    fetch(PUBLIC_NOTICE_EXTRACT_WEB_HOOK_URL, {
      method: "POST",
      body: JSON.stringify(msg),
      headers: {
        "Content-Type": "application/json; charset=utf-8"
      }
    });

  console.log(webHookResponse);
  console.log(await webHookResponse.text());

  await fileSendCompletion;
  console.log("Finished");
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});


async function sendToBucket(publicNotices: PnPData[], date: Date) {
  try {

    
    const storage = new Storage();
    const bucketName = process.env.GCLOUD_STORAGE_BUCKET_NAME || "public-notices-extract";
    const fileName = `public_notices_${date.toISOString().substring(0, 10)}.json`;
    
    const bucket = storage.bucket(bucketName);
    const file = bucket.file(fileName);
    
    await file.save(JSON.stringify(publicNotices, null, 2), {
      contentType: 'application/json'
    });
    
    console.log(`Saved ${publicNotices.length} public notices to gs://${bucketName}/${fileName}`);
  } catch (error) {
    console.error("Error saving to bucket:", error);
    // no rethrow, we don't want to fail the whole process if saving to bucket fails
  }

}