import * as functions from "firebase-functions";

import * as admin from "firebase-admin";

import axios from "axios";

admin.initializeApp();

export const setUsername = functions.https.onCall(async (data, context) => {
  const username: string = data.username;

  if (
    !(typeof username === "string") ||
    username.length < 1 ||
    // Check username has no spaces
    username.indexOf(" ") >= 0
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You need to specify a valid username which must be greater than 1 character in length (with no spaces)."
    );
  }

  if (!context.auth) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;

  const usersRef = admin.firestore().collection("users");

  const username_lowercase: string = username.toLowerCase();

  const snapshot = await usersRef
    .where("username_lowercase", "==", username_lowercase)
    .get();

  if (snapshot.empty) {
    await usersRef
      .doc(uid)
      .set({ username, username_lowercase }, { merge: true });

    return { username };
  } else {
    throw new functions.https.HttpsError(
      "already-exists",
      "Someone has already registered this username!"
    );
  }
});

export const followUser = functions.https.onCall(async (data, context) => {
  const toFollowUserID: string = data.userID;

  if (
    !(typeof toFollowUserID === "string") ||
    toFollowUserID.length < 1 ||
    // Check userID has no spaces
    toFollowUserID.indexOf(" ") >= 0
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You need to specify a valid userID which must be greater than 1 character in length (with no spaces)."
    );
  }

  if (!context.auth) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;

  const usersRef = admin.firestore().collection("users");

  // Remove from following list
  await usersRef
    .doc(uid)
    .set(
      { following: admin.firestore.FieldValue.arrayUnion(toFollowUserID) },
      { merge: true }
    );

  // Remove from followers list
  await usersRef
    .doc(toFollowUserID)
    .set(
      { followers: admin.firestore.FieldValue.arrayUnion(uid) },
      { merge: true }
    );

  return { toFollowUserID };
});

export const unFollowUser = functions.https.onCall(async (data, context) => {
  const toUnFollowUserID: string = data.userID;

  if (
    !(typeof toUnFollowUserID === "string") ||
    toUnFollowUserID.length < 1 ||
    // Check userID has no spaces
    toUnFollowUserID.indexOf(" ") >= 0
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You need to specify a valid userID which must be greater than 1 character in length (with no spaces)."
    );
  }

  if (!context.auth) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;

  const usersRef = admin.firestore().collection("users");

  // Remove from following list
  await usersRef
    .doc(uid)
    .set(
      { following: admin.firestore.FieldValue.arrayRemove(toUnFollowUserID) },
      { merge: true }
    );

  // Remove from followers list
  await usersRef
    .doc(toUnFollowUserID)
    .set(
      { followers: admin.firestore.FieldValue.arrayRemove(uid) },
      { merge: true }
    );

  return { toUnFollowUserID };
});

export const createPost = functions.https.onCall(async (data, context) => {
  const title: string = data.title;
  const imageURL: string = data.imageURL;

  if (!(typeof title === "string")) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You need to specify a valid title (a string)!"
    );
  }

  if (!(typeof imageURL === "string") || imageURL.length < 1) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "You need to specify a valid imageURL which must be greater than 1 character in length."
    );
  }

  if (!context.auth) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;

  const response = await axios.post<{
    image_0: string;
    image_1: string;
    image_2: string;
    image_3: string;
    image_4: string;
  }>("https://crows.sh/polargramExposure", {
    image_link: imageURL,
  });

  await admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("posts")
    .add({
      title: title,
      timestamp: Date.now(),
      ...response.data,
    });

  return { success: true };
});

export const getFeed = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;

  const yourProfile = await admin
    .firestore()
    .collection("users")
    .doc(uid)
    .get();

  const following: string[] = yourProfile.get("following") ?? [];

  let postRefrences: {
    postID: string;
    userID: string;
    timestamp: number;
  }[] = [];

  // Allow people to see posts from "Ben" if they are not following anyone.
  if (following.length == 0) {
    following.push("KRh7oylId0b6bZyzquT32a56CkP2");
  }

  if (following.length != 0) {
    for (const userID of following) {
      const userPosts = await admin
        .firestore()
        .collection("users")
        .doc(userID)
        .collection("posts")
        .orderBy("timestamp", "desc")
        .limit(5)
        .get();

      for (const post of userPosts.docs) {
        postRefrences.push({
          postID: post.id,
          userID: userID,
          timestamp: post.get("timestamp"),
        });
      }
    }
  }

  return postRefrences;
});
