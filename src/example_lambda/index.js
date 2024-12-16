exports.handler = async (event) => {
  console.log("main lambda invoked");
  const response = {
    statusCode: 200,
    body: JSON.stringify({
      message: "Hello, World!",
    }),
  };
  return response;
};
