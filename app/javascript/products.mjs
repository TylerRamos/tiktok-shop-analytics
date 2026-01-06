import { getProductsRaw } from "./products-raw.mjs";

// Read stdin for input data
let inputData = "";

process.stdin.on("data", (chunk) => {
  inputData += chunk;
});

process.stdin.on("end", async () => {
  try {
    const params = JSON.parse(inputData);

    // Call the function with the provided parameters
    const result = await getProductsRaw({
      cookie: params.cookie,
      oecSellerId: params.oecSellerId,
      baseUrl: params.baseUrl,
      fp: params.fp,
      timezoneOffset: params.timezoneOffset,
      startDate: params.startDate,
      endDate: params.endDate,
      page: params.page,
      pageSize: params.pageSize,
    });

    // Output the result as JSON
    console.log(JSON.stringify(result));
  } catch (error) {
    console.error(
      JSON.stringify({
        status_code: -1,
        status_msg: error.message,
        error: true,
      })
    );
    process.exit(1);
  }
});