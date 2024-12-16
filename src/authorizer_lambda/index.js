const jwt = require("jsonwebtoken");
const { promisify } = require("util");
const jwksClient = require("jwks-rsa");

const deny = (event) => ({
  principalId: "TBC",
  policyDocument: {
    Version: "2012-10-17",
    Statement: [
      {
        Action: "execute-api:Invoke",
        Effect: "Deny",
        Resource: event.methodArn,
      },
    ],
  },
});

const allow = (event) => ({
  principalId: "TBC",
  policyDocument: {
    Version: "2012-10-17",
    Statement: [
      {
        Action: "execute-api:Invoke",
        Effect: "Allow",
        Resource: event.methodArn,
      },
    ],
  },
});

const auth0 = {
  jwksUri: process.env.JWKS_URI,
  issuer: process.env.ISSUER,
  audience: process.env.AUDIENCE,
};

const client = jwksClient({
  jwksUri: auth0.jwksUri,
});

// TODO: don't do this on each invocation
function getKey(header, callback) {
  client.getSigningKey(header.kid, function (err, key) {
    const signingKey = key.publicKey || key.rsaPublicKey;
    callback(null, signingKey);
  });
}

exports.handler = async (event) => {
  try {
    const token = event?.headers?.Authorization?.split(" ")[1];

    const user = await promisify(jwt.verify)(token, getKey, {
      issuer: auth0.issuer,
      audience: auth0.audience,
    });

    if (!user) {
      return deny(event);
    }

    return allow(event);
  } catch (error) {
    return deny(event);
  }
};
