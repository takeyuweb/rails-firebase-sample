import firebase, { auth } from "./firebase";
import * as React from "react";
import StyledFirebaseAuth from "react-firebaseui/StyledFirebaseAuth";
import { FirebaseAuth } from "react-firebaseui";

const uiConfig = {
  signInFlow: "popup",
  signInOptions: [
    firebase.auth.EmailAuthProvider.PROVIDER_ID,
    firebase.auth.GoogleAuthProvider.PROVIDER_ID
  ]
};

export interface InjectedProps {
  auth: firebase.auth.Auth;
}

interface WrappedComponentProps {}

interface WrappedComponentState {
  loading: boolean;
  isLoggedIn: boolean;
}

export const withAuth = (
  ChildComponent: React.ComponentType<InjectedProps>
) => {
  return class WrappedComponent extends React.Component<
    WrappedComponentProps,
    WrappedComponentState
  > {
    constructor(props) {
      super(props);

      this.state = {
        loading: true,
        isLoggedIn: false
      };
    }

    componentDidMount() {
      auth.onAuthStateChanged((user: any) => {
        if (user) {
          this.setState({ isLoggedIn: true, loading: false });
        } else {
          this.setState({ isLoggedIn: false, loading: false });
        }
      });
    }

    render() {
      if (this.state.loading) {
        return <p>Loading</p>;
      }

      if (this.state.isLoggedIn) {
        console.log(auth.currentUser);
        return <ChildComponent auth={auth} />;
      } else {
        return (
          <StyledFirebaseAuth
            uiConfig={uiConfig}
            firebaseAuth={auth}
          ></StyledFirebaseAuth>
        );
      }
    }
  };
};
