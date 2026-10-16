namespace VeroEqulibraFit.Contracts.Auth;

public sealed record RegisterRequest(string Email, string Password, string? DisplayName);
public sealed record RegistrationResponse(string Message);
public sealed record LoginRequest(string Email, string Password);
public sealed record RefreshRequest(string RefreshToken);
public sealed record AuthResponse(string AccessToken, string RefreshToken, DateTimeOffset AccessTokenExpiresAt, string UserId, string Email, string? DisplayName);
public sealed record SessionResponse(string UserId, string Email, string? DisplayName);
public sealed record ForgotPasswordRequest(string Email);
public sealed record ResetPasswordRequest(string UserId, string Token, string NewPassword);
public sealed record ConfirmEmailRequest(string UserId, string Token);
public sealed record ResendConfirmationRequest(string Email);
