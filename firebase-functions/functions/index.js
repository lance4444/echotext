const FormData = require("form-data");
const fetch = require("node-fetch");
const admin = require("firebase-admin");
const { onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");

const firebaseConfig = {
  apiKey: "AIzaSyCE_m2nOTlLPoftrXgu0h-MD7XfaQ85mm0",
  authDomain: "onlyaudio-74ba7.firebaseapp.com",
  projectId: "onlyaudio-74ba7",
  storageBucket: "onlyaudio-74ba7.firebasestorage.app",
  messagingSenderId: "378144589866",
  appId: "1:378144589866:web:3b281d1dff5ac80f411b53",
  measurementId: "G-JHXVEFJK0G"
};
admin.initializeApp(firebaseConfig);

const GROQ_API_KEY = "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";

exports.transcribes = onDocumentCreated( "myaudio/{docId}", async (event) => {
    try {
        const snapshot = await event.data;
        console.log(snapshot);
        const audioData = snapshot.data();
        const audioUrl = audioData.mp4Url.toString();
        console.log(audioUrl);
        const formData = new FormData();
        formData.append("url", audioUrl);
        formData.append("model", "whisper-large-v3");
        formData.append("temperature", "0");
        formData.append("response_format", "json");
        formData.append("language", "yue");

        const result = await fetch("https://api.groq.com/openai/v1/audio/transcriptions", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${GROQ_API_KEY}`
            },
            body: formData
        });

        const data = await result.json();
         await admin.firestore().collection("myaudio").doc(snapshot.id).update({
          txtMsg: data.text,
      });
        // response.json(data);
    } catch (error) {
        // response.status(500).json({
        //     error: error.message,
        //     details: "Error processing transcription request"
        // });
    }
});

exports.findKeyWord = onDocumentUpdated( "myaudio/{docId}", async (event) => {
    try {
        const snapshot = await event.data;
        const afterData = snapshot.after.data();
        const beforeData = snapshot.before.data();
        if (afterData.txtMsg === beforeData.txtMsg) {
            return;
        }
        const txtMsg = afterData.txtMsg;

     const resultWord = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
          "Content-Type": `application/json`,
          "Authorization": `Bearer ${GROQ_API_KEY}`
      },
      body: JSON.stringify({
        model: "llama-3.1-8b-instant",
          messages: [
            {
                role: "system",
                content: "你是一個關鍵字提取助手。請只從文本中提取關鍵字和同義詞，並以逗號分隔的列表形式輸出。.其他不用回答。"
            },
            {
                role: "user",
                content: `${txtMsg}`
            }
        ],
        temperature: 0,
        max_tokens: 1024,
        top_p: 1,
        stream: false,
      })
    });
    if (!resultWord.ok) {
      const errorText = await resultWord.text();
      console.error('API Error:', errorText);
      throw new Error(`API call failed: ${resultWord.statusText}`);
  }

    const data = await resultWord.json();

    console.log('Keyword extraction result:', data);
    let content = data.choices[0].message.content;
    content = content
      .replace(/、/g, ',')
      .replace(/，/g, ',')
      .replace(/\./g, ',')
      .replace(/;/g, ',');
    const keywordsArray = content
    .split(",")
    .map((keyword) => keyword.trim());
    console.log('.................................', keywordsArray);
    await admin.firestore().collection("myaudio").doc(snapshot.after.id).update({
    keyWord: keywordsArray,
  });
} catch (error) {
  console.error('Error in keyword extraction:', error);
  throw error;
}
});


