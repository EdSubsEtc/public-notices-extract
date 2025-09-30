const PUBLIC_NOTICE_EXTRACT_WEB_HOOK_URL = process.env.WEB_HOOK_URL || "https://chat.googleapis.com/v1/spaces/AAAAFIcw4FE/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=saT5iu2zFrfWfiPzMy4wFkEw-gZUpxfXxp8Yrk3HoqU";

import { publicNoticesExtract } from './sql-runner';

async function main() {
  console.log("started");

  const randomSentence = createRandomSentence() + `\nSent at ${new Date()}`;

  const publicNotices = await publicNoticesExtract();

  const msg = {
    text: `timestamp: ${new Date().toISOString()}\n\n${randomSentence}\n\n${publicNotices}`,
  };

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

  console.log("Finished");
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});





function createRandomSentence(): String {

  const randomWords = [
    "apple", "banana", "cherry", "date", "elderberry", "fig", "grape", "honeydew", "kiwi", "lemon",
    "mango", "nectarine", "orange", "papaya", "quince", "raspberry", "strawberry", "tangerine", "ugli", "vanilla",
    "watermelon", "xigua", "yellowfruit", "zucchini", "apricot", "blueberry", "cantaloupe", "dragonfruit", "eggplant", "fennel",
    "ginger", "huckleberry", "iceberg", "jicama", "kale", "lime", "mushroom", "nutmeg", "olive", "pear",
    "quinoa", "radish", "spinach", "tomato", "turnip", "umbrella", "vinegar", "walnut", "yam", "zest",
    "almond", "basil", "cabbage", "dill", "endive", "fava", "garlic", "hazelnut", "indigo", "jalapeno",
    "kohlrabi", "lentil", "millet", "noodle", "oat", "pecan", "quail", "rice", "sage", "thyme",
    "udon", "vegetable", "wheat", "xanthan", "yogurt", "ziti", "artichoke", "broccoli", "cauliflower", "dandelion",
    "endive", "fennel", "guava", "horseradish", "icicle", "juniper", "kumquat", "lettuce", "macadamia", "navybean",
    "okra", "parsley", "quince", "romaine", "scallion", "tapioca", "urad", "vermicelli", "watercress", "xmas",
    "yarrow", "zucchini"

  ];

  let sentence = "";
  const maxWords = 4 + Math.floor(Math.random() * 16);
  for (let n: number = 0; n < maxWords; n++) {
    sentence += randomWords[Math.floor(Math.random() * randomWords.length)] + " ";
  }

  sentence = sentence[0]?.toUpperCase() + sentence.slice(1) + ".";

  return sentence;

}
