import * as React from "react";
import { render } from "react-dom";
import { withAuth, InjectedProps } from "./auth";

const App: React.FC<InjectedProps> = props => {
  return <div>Hello, {props.auth.currentUser.displayName}!</div>;
};

const WrappedApp = withAuth(App);

document.addEventListener("DOMContentLoaded", () => {
  render(<WrappedApp />, document.getElementById("app"));
});
