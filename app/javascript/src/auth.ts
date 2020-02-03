import * as firebaseui from "firebaseui";
import "firebaseui/dist/firebaseui.css";

import firebase from "./firebase";

document.addEventListener("DOMContentLoaded", () => {
  const authContainer = document.getElementById("firebaseui-auth-container");
  if (authContainer) {
    uiStart(authContainer);
  }
});

const uiStart = (authContainer: HTMLElement) => {
  const uiConfig = {
    callbacks: {
      signInSuccessWithAuthResult: function(authResult, redirectUrl) {
        // User successfully signed in.
        // Return type determines whether we continue the redirect automatically
        // or whether we leave that to developer to handle.
        console.log(authResult);
        authResult.user
          .getIdToken(true)
          .then(idToken => {
            createSession(idToken)
              .then(res => {
                if (res.ok) {
                  console.log(res);
                  location.assign("/");
                } else {
                  console.error(res);
                }
              })
              .catch(e => {
                console.error(e);
              });
          })
          .catch(error => {
            console.log(`Firebase getIdToken failed!: ${error.message}`);
          });
        return false;
      },
      uiShown: function() {
        document.getElementById("loader").style.display = "none";
      }
    },
    signInFlow: "redirect",
    signInOptions: [
      firebase.auth.EmailAuthProvider.PROVIDER_ID,
      firebase.auth.GoogleAuthProvider.PROVIDER_ID
    ]
  };

  // The start method will wait until the DOM is loaded.
  const ui = new firebaseui.auth.AuthUI(firebase.auth());
  ui.start(authContainer, uiConfig);
};

const getCsrfToken = () => {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
    .content;
};

const authorizationObj = idToken => {
  return { Authorization: `Bearer ${idToken}` };
};

const createSession = (idToken: string) => {
  const csrfToken = getCsrfToken();
  const postData = {
    idToken: idToken
  };

  return fetch("/session", {
    method: "POST",
    mode: "same-origin",
    cache: "no-cache",
    credentials: "include",
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "X-CSRF-TOKEN": csrfToken
    },
    body: JSON.stringify(postData)
  });
};
