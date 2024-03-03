using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Sanduba.Auth.Api.Application.ResponseModel;
using Sanduba.Auth.Api.Application.RequestModel;
using Sanduba.Auth.Api.Application;
using System.Web.Http;

namespace Sanduba.Auth.Function
{
    public static class LoginUser
    {
        [FunctionName("LoginUser")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "auth")] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

            LoginResponse response;

            try
            {

                if (string.IsNullOrEmpty(requestBody))
                {
                    response = LoginService.LoginAnonymousUser();
                }
                else
                {
                    IdentifiedUserRequest loginRequest;

                    try
                    {
                        loginRequest = JsonConvert.DeserializeObject<IdentifiedUserRequest>(requestBody);
                    }
                    catch
                    {
                        log.LogError($"Invalid request: {requestBody}");
                        return new BadRequestObjectResult("Invalid username/password!");
                    }

                    response = LoginService.LoginIdentifiedUser(loginRequest);
                }

                if (response == null || response.Status != "Success")
                {
                    return new BadRequestObjectResult(response);
                }
                else
                    return new OkObjectResult(response);

                return new OkObjectResult(response);
            }
            catch( Exception ex )
            {
                log.LogError(ex, "Error");
                return new InternalServerErrorResult();
            }
        }
    }
}
