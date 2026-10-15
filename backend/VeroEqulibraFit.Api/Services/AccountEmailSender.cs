using System.Net;
using System.Net.Mail;

namespace VeroEqulibraFit.Api.Services;

public interface IAccountEmailSender
{
    Task SendPasswordResetAsync(string email, string resetUrl, CancellationToken cancellationToken);
}

public sealed class SmtpAccountEmailSender(IConfiguration configuration) : IAccountEmailSender
{
    public async Task SendPasswordResetAsync(string email, string resetUrl, CancellationToken cancellationToken)
    {
        var host = configuration["Email:SmtpHost"] ?? throw new InvalidOperationException("Transactional email is not configured.");
        var from = configuration["Email:From"] ?? throw new InvalidOperationException("Transactional email sender is not configured.");
        using var client = new SmtpClient(host, configuration.GetValue("Email:SmtpPort", 587))
        {
            EnableSsl = configuration.GetValue("Email:UseSsl", true),
            Credentials = new NetworkCredential(configuration["Email:Username"], configuration["Email:Password"]),
        };
        using var message = new MailMessage(from, email)
        {
            Subject = "Redefina sua senha do VeroEqulibraFit+",
            Body = $"Use este link único para redefinir sua senha: {resetUrl}",
        };
        await client.SendMailAsync(message, cancellationToken);
    }
}
