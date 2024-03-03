using Newtonsoft.Json;
using System.ComponentModel.DataAnnotations;

namespace Sanduba.Auth.Api.Application.RequestModel
{
    public record IdentifiedUserRequest([Required] string Username, [Required] string Password);
}
