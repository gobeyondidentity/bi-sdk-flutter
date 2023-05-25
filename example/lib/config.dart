// THIS FILE IS GENERATED. DO NOT EDIT.

import 'package:embeddedsdk/embeddedsdk.dart';

class BuildConfig {
  // Client ID for the confidential client flow
  static const CONFIDENTIAL_CLIENT_ID_US = "f172aea460fdf56a7f0da2cbdd96ead5";

  static const CONFIDENTIAL_CLIENT_ID_EU = "ff6e6e00bba30c985509a394978b8700";

  static String getConfidentialClientId(Domain domain) => domain == Domain.eu
      ? BuildConfig.CONFIDENTIAL_CLIENT_ID_EU
      : BuildConfig.CONFIDENTIAL_CLIENT_ID_US;

  // Client secret for the confidential client flow
  static const CONFIDENTIAL_CLIENT_SECRET_US = "b3a0c298f4c0a2ef1a7eef2ad7053250";

  static const CONFIDENTIAL_CLIENT_SECRET_EU = "9641a3f74bc733276300a06687124efa";

  static String getConfidentialClientSecret(Domain domain) => domain == Domain.eu
      ? BuildConfig.CONFIDENTIAL_CLIENT_SECRET_EU
      : BuildConfig.CONFIDENTIAL_CLIENT_SECRET_US;

  // Client ID for the public client flow
  static const PUBLIC_CLIENT_ID_US = "8213791482b9997c0fb648ed5c6c3ee3";

  static const PUBLIC_CLIENT_ID_EU = "3518a950624bbafc1ddd467eee07b628";

  static String getPublicClientId(Domain domain) => domain == Domain.eu
      ? BuildConfig.PUBLIC_CLIENT_ID_EU
      : BuildConfig.PUBLIC_CLIENT_ID_US;

  // Auth redirect uri
  static const REDIRECT_URI = "acme://";

  // This would be your backend endpoint to recover an existing user.
  static const RECOVER_USER_URL_US = "https://api.byndid.com/v1/manage/recover-user";

  static const RECOVER_USER_URL_EU = "https://api-eu.byndid.com/v1/manage/recover-user";

  static String getRecoverUserUrl(Domain domain) => domain == Domain.eu
      ? BuildConfig.RECOVER_USER_URL_EU
      : BuildConfig.RECOVER_USER_URL_US;

  // This would be your backend endpoint to register a new user.
  static const CREATE_USER_URL_US = "https://api.byndid.com/v1/manage/users";

  static const CREATE_USER_URL_EU = "https://api-eu.byndid.com/v1/manage/users";

  static String getCreateUserUrl(Domain domain) => domain == Domain.eu
      ? BuildConfig.CREATE_USER_URL_EU
      : BuildConfig.CREATE_USER_URL_US;

  // This is the endpoint your server would call to make the token exchange.
  static const TOKEN_ENDPOINT_US = "https://auth.byndid.com/v2/token";

  static const TOKEN_ENDPOINT_EU = "https://auth-eu.byndid.com/v2/token";

  static String getTokenEndpoint(Domain domain) => domain == Domain.eu
      ? BuildConfig.TOKEN_ENDPOINT_EU
      : BuildConfig.TOKEN_ENDPOINT_US;

  // This is the endpoint your server would call to make the token exchange.
  static const DEMO_TENANT_HANDLE = "sdk-demo";

  // This is the bearer api token for api calls
  static String getApiToken(Domain domain) => "TODO";
}
