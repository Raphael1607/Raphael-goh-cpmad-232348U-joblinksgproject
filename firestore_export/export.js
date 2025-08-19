const admin = require("firebase-admin");
const fs = require("fs");

// ✅ Load your Firebase service account key (download from Firebase Console)
const serviceAccount = require("./fs-apikey.json");


// ✅ Initialize Firestore
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// ✅ Collections you want to export
const collections = [
  "applied_jobs",
  "companies",
  "company_portfolios",
  "profiles"
];

// 🔹 Export function
async function exportCollections() {
  for (const col of collections) {
    console.log(`Exporting collection: ${col}...`);

    const snapshot = await db.collection(col).get();
    const docs = {};

    snapshot.forEach((doc) => {
      docs[doc.id] = doc.data();
    });

    fs.writeFileSync(
      `${col}.json`,
      JSON.stringify(docs, null, 2)
    );

    console.log(`✅ Exported ${snapshot.size} docs from "${col}" to ${col}.json`);
  }
  console.log("🎉 Export complete!");
}

exportCollections().catch((err) => {
  console.error("Error exporting collections:", err);
});
