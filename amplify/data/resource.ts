import { type ClientSchema, a, defineData } from "@aws-amplify/backend";

const schema = a.schema({
  Score: a.model({
      leaderboard: a.string().required(),
      username: a.string().required(),
      score: a.integer().required(),
    }).identifier(["leaderboard", "username"])
      .secondaryIndexes(index => [index("leaderboard").sortKeys(["score"])])
      .authorization(allow => [allow.authenticated()])
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});