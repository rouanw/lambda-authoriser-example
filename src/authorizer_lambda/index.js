exports.handler = async (event) => {
  const isAuthorized = event?.headers?.Authorization?.includes("SECRET");

  if (!isAuthorized) {
    return JSON.stringify({
      statusCode: 200,
      body: {
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
      },
    });
  }

  return {
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
  };
};
