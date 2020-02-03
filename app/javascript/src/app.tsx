import * as React from "react";
import { render } from "react-dom";
import { withAuth, InjectedProps } from "./auth";
import { ApolloProvider } from "@apollo/react-hooks";
import client from "./apollo";
import { gql } from "apollo-boost";
import { useQuery } from "@apollo/react-hooks";

const TEST_FIELD = gql`
  {
    testField
  }
`;

const GraphQLTest: React.FC<{}> = props => {
  const { loading, error, data } = useQuery(TEST_FIELD);

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;

  return <p>testField: {data.testField}</p>;
};

const App: React.FC<InjectedProps> = props => {
  return (
    <ApolloProvider client={client}>
      <p>Hello, {props.auth.currentUser.displayName}!</p>
      <GraphQLTest />
    </ApolloProvider>
  );
};

const WrappedApp = withAuth(App);

document.addEventListener("DOMContentLoaded", () => {
  render(<WrappedApp />, document.getElementById("app"));
});
