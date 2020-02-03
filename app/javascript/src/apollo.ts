import ApolloClient from "apollo-boost";
import { auth } from "./firebase";

const client = new ApolloClient({
  uri: "/graphql",
  request: async operation => {
    // IdToken を取得
    // リフレッシュは getIdToken がよしなにしてくれるので、通常気にする必要はない
    const idToken = await auth.currentUser.getIdToken();
    // GraphQLリクエストに付けて送る
    // サーバ側では受け取った IdToken を検証して正しければ処理を継続する
    if (idToken) {
      operation.setContext({
        headers: {
          authorization: `Bearer ${idToken}`
        }
      });
    }
  }
});

export default client;
