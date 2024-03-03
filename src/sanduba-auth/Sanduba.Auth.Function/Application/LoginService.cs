using Sanduba.Auth.Api.Application.RequestModel;
using Sanduba.Auth.Api.Application.ResponseModel;
using Sanduba.Auth.Api.Gateway;
using System;

namespace Sanduba.Auth.Api.Application
{
    public static class LoginService
    {
        private static readonly LoginPersistenceGateway _loginPersistence = new();
        private static readonly SecurityGateway _securityGateway = new();

        public static LoginResponse LoginIdentifiedUser(IdentifiedUserRequest requestModel)
        {
            string hashPassword = _securityGateway.GetHashPassword(requestModel.Password);

            System.Guid? userId = _loginPersistence.GetUserId(requestModel.Username, hashPassword);

            if (userId is not null)
            {
                string token = _securityGateway.GenerateJwt(userId);

                return new LoginResponse("Success", token);
            }
            else
            {
                return new LoginResponse("Failure", "Invalid UserName/Passaword!!!");
            }
        }

        public static LoginResponse LoginAnonymousUser()
        {
            string token = _securityGateway.GenerateJwt(Guid.NewGuid());

            return new LoginResponse("Success", token);
        }
    }
}