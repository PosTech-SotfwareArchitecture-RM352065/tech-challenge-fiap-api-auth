using Sanduba.Auth.Api.Application;
using System;

namespace Sanduba.Auth.Api.Gateway
{
    public sealed class LoginPersistenceGateway
    {
        public Guid? GetUserId(string userName, string hashPassword)
        {
            return Guid.NewGuid();
        }
    }
}
