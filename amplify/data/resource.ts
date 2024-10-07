import { type ClientSchema, a, defineData } from "@aws-amplify/backend";

const schema = a.schema({
  Leaderboard: a
    .model({
      username: a.id().required(),
      score: a.integer().required()
    }).authorization(allow => [allow.authenticated()])
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});