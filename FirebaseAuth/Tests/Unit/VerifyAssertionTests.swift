// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import XCTest

@testable import FirebaseAuth

class VerifyAssertionTests: RPCBaseTests {
  private let kTestProviderID = "ProviderID"
  private let kProviderIDKey = "providerId"
  private let kProviderAccessTokenKey = "access_token"
  private let kTestProviderAccessToken = "testProviderAccessToken"
  private let kPostBodyKey = "postBody"
  private let kIDTokenKey = "idToken"
  private let kReturnSecureTokenKey = "returnSecureToken"
  private let kAutoCreateKey = "autoCreate"
  private let kProviderIDTokenKey = "id_token"
  private let kTestProviderIDToken = "ProviderIDToken"
  private let kTestAccessToken = "ACCESS_TOKEN"
  private let kInputEmailKey = "identifier"
  private let kTestInputEmail = "testInputEmail"
  private let kTestPendingToken = "testPendingToken"
  private let kProviderOAuthTokenSecretKey = "oauth_token_secret"
  private let kTestProviderOAuthTokenSecret = "testProviderOAuthTokenSecret"
  private let kTestIDToken = "ID_TOKEN"
  private let kTestExpiresIn = "12345"
  private let kTestRefreshToken = "REFRESH_TOKEN"
  private let kTestProvider = "Provider"
  private let kPhotoUrlKey = "photoUrl"
  private let kTestPhotoUrl = "www.example.com"
  private let kUsername = "Joe Doe"
  private let kVerifiedProviderKey = "verifiedProvider"
  private let kExpiresInKey = "expiresIn"
  private let kRefreshTokenKey = "refreshToken"
  private let kRawUserInfoKey = "rawUserInfo"
  private let kUsernameKey = "username"
  private let kIsNewUserKey = "isNewUser"
  private let kExpectedAPIURL =
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyAssertion?key=APIKey"

  /** @fn testVerifyAssertionRequestProviderAccessToken
      @brief Tests the verify assertion request with the @c providerAccessToken field set.
      @remarks The presence of the @c providerAccessToken will prevent an @c
          InvalidArgumentException exception from being raised.
   */
  func testVerifyAssertionRequestProviderAccessToken() throws {
    let request = makeVerifyAssertionRequest()
    request.returnSecureToken = false
    let issuer = try checkRequest(
      request: request,
      expected: kExpectedAPIURL,
      key: kIDTokenKey,
      value: nil
    )
    var components = URLComponents()
    components.queryItems = [
      URLQueryItem(name: kProviderIDKey, value: kTestProviderID),
      URLQueryItem(name: kProviderAccessTokenKey, value: kTestProviderAccessToken),
    ]

    let requestDictionary = try XCTUnwrap(issuer.decodedRequest as? [String: AnyHashable])
    XCTAssertEqual(requestDictionary[kPostBodyKey], components.query)
    XCTAssertNil(requestDictionary[kReturnSecureTokenKey])
    // Auto-create flag Should be true by default.
    XCTAssertTrue(try XCTUnwrap(requestDictionary[kAutoCreateKey] as? Bool))
  }

  /** @fn testVerifyAssertionRequestOptionalFields
      @brief Tests the verify assertion request with all optinal fields set.
   */
  func testVerifyAssertionRequestOptionalFields() throws {
    let request = makeVerifyAssertionRequest()
    request.providerIDToken = kTestProviderIDToken
    request.accessToken = kTestAccessToken
    request.inputEmail = kTestInputEmail
    request.pendingToken = kTestPendingToken
    request.providerOAuthTokenSecret = kTestProviderOAuthTokenSecret
    request.autoCreate = false
    let kFakeGivenName = "Paul"
    let kFakeFamilyName = "B"
    var fullName = PersonNameComponents()
    fullName.givenName = kFakeGivenName
    fullName.familyName = kFakeFamilyName
    request.fullName = fullName

    // The name fields may be sorted either way.
    let userJSON = "{\"name\":{\"firstName\":\"\(kFakeGivenName)\"," +
      "\"lastName\":\"\(kFakeFamilyName)\"}}"

    let issuer = try checkRequest(
      request: request,
      expected: kExpectedAPIURL,
      key: kIDTokenKey,
      value: kTestAccessToken
    )
    var components = URLComponents()
    components.queryItems = [
      URLQueryItem(name: kProviderIDKey, value: kTestProviderID),
      URLQueryItem(name: kProviderIDTokenKey, value: kTestProviderIDToken),
      URLQueryItem(name: kProviderAccessTokenKey, value: kTestProviderAccessToken),
      URLQueryItem(name: kProviderOAuthTokenSecretKey, value: kTestProviderOAuthTokenSecret),
      URLQueryItem(name: kInputEmailKey, value: kTestInputEmail),
      URLQueryItem(name: "user", value: userJSON),
    ]

    let requestDictionary = try XCTUnwrap(issuer.decodedRequest as? [String: AnyHashable])
    XCTAssertEqual(requestDictionary[kPostBodyKey], components.query)
    XCTAssertTrue(try XCTUnwrap(requestDictionary[kReturnSecureTokenKey] as? Bool))
    XCTAssertFalse(try XCTUnwrap(requestDictionary[kAutoCreateKey] as? Bool))
  }

  func testVerifyAssertionRequestErrors() throws {
    let kTestInvalidCredentialError = "INVALID_IDP_RESPONSE"
    let kUserDisabledErrorMessage = "USER_DISABLED"
    let kFederatedUserIDAlreadyLinkedMessage = "FEDERATED_USER_ID_ALREADY_LINKED:"
    let kOperationNotAllowedErrorMessage = "OPERATION_NOT_ALLOWED"
    let kPasswordLoginDisabledErrorMessage = "PASSWORD_LOGIN_DISABLED"

    try checkBackendError(
      request: makeVerifyAssertionRequest(),
      message: kTestInvalidCredentialError,
      errorCode: AuthErrorCode.invalidCredential
    )
    try checkBackendError(
      request: makeVerifyAssertionRequest(),
      message: kUserDisabledErrorMessage,
      errorCode: AuthErrorCode.userDisabled
    )
    try checkBackendError(
      request: makeVerifyAssertionRequest(),
      message: kFederatedUserIDAlreadyLinkedMessage,
      errorCode: AuthErrorCode.credentialAlreadyInUse
    )
    try checkBackendError(
      request: makeVerifyAssertionRequest(),
      message: kOperationNotAllowedErrorMessage,
      errorCode: AuthErrorCode.operationNotAllowed
    )
    try checkBackendError(
      request: makeVerifyAssertionRequest(),
      message: kPasswordLoginDisabledErrorMessage,
      errorCode: AuthErrorCode.operationNotAllowed
    )
  }

  private let profile = [
    "iss": "https://accounts.google.com\\",
    "email": "test@email.com",
    "given_name": "User",
    "family_name": "Doe",
  ]

  /** @fn testSuccessfulVerifyAssertionResponse
      @brief This test simulates a successful verify assertion flow.
   */
  func testSuccessfulVerifyAssertionResponse() throws {
    var callbackInvoked = false
    var rpcResponse: VerifyAssertionResponse?
    var rpcError: NSError?

    AuthBackend.post(with: makeVerifyAssertionRequest()) { response, error in
      callbackInvoked = true
      rpcResponse = response
      rpcError = error as? NSError
    }

    _ = try rpcIssuer?.respond(withJSON: [
      kProviderIDKey: kTestProviderID,
      kIDTokenKey: kTestIDToken,
      kExpiresInKey: kTestExpiresIn,
      kRefreshTokenKey: kTestRefreshToken,
      kVerifiedProviderKey: [kTestProvider],
      kPhotoUrlKey: kTestPhotoUrl,
      kUsernameKey: kUsername,
      kIsNewUserKey: true,
      kRawUserInfoKey: profile,
    ])

    XCTAssert(callbackInvoked)
    XCTAssertNil(rpcError)
    XCTAssertEqual(rpcResponse?.idToken, kTestIDToken)
    XCTAssertEqual(rpcResponse?.refreshToken, kTestRefreshToken)
    XCTAssertEqual(rpcResponse?.verifiedProvider, [kTestProvider])
    XCTAssertEqual(rpcResponse?.photoURL, URL(string: kTestPhotoUrl))
    XCTAssertEqual(rpcResponse?.username, kUsername)
    XCTAssertEqual(try XCTUnwrap(rpcResponse?.profile as? [String: String]), profile)
    let expiresIn = try XCTUnwrap(rpcResponse?.approximateExpirationDate?.timeIntervalSinceNow)
    XCTAssertEqual(expiresIn, 12345, accuracy: 0.1)
    XCTAssertEqual(rpcResponse?.providerID, kTestProviderID)
    XCTAssertTrue(try XCTUnwrap(rpcResponse?.isNewUser))
  }

  /** @fn testSuccessfulVerifyAssertionResponseWithTextData
      @brief This test simulates a successful verify assertion flow when response collection
          fields are sent as text values.
   */
  func testSuccessfulVerifyAssertionResponseWithTextData() throws {
    var callbackInvoked = false
    var rpcResponse: VerifyAssertionResponse?
    var rpcError: NSError?

    AuthBackend.post(with: makeVerifyAssertionRequest()) { response, error in
      callbackInvoked = true
      rpcResponse = response
      rpcError = error as? NSError
    }

    _ = try rpcIssuer?.respond(withJSON: [
      kProviderIDKey: kTestProviderID,
      kIDTokenKey: kTestIDToken,
      kExpiresInKey: kTestExpiresIn,
      kRefreshTokenKey: kTestRefreshToken,
      kVerifiedProviderKey: convertToJson([kTestProvider]),
      kPhotoUrlKey: kTestPhotoUrl,
      kUsernameKey: kUsername,
      kIsNewUserKey: false,
      kRawUserInfoKey: convertToJson(profile),
    ])

    XCTAssert(callbackInvoked)
    XCTAssertNil(rpcError)
    XCTAssertEqual(rpcResponse?.idToken, kTestIDToken)
    XCTAssertEqual(rpcResponse?.refreshToken, kTestRefreshToken)
    XCTAssertEqual(rpcResponse?.verifiedProvider, [kTestProvider])
    XCTAssertEqual(rpcResponse?.photoURL, URL(string: kTestPhotoUrl))
    XCTAssertEqual(rpcResponse?.username, kUsername)
    XCTAssertEqual(try XCTUnwrap(rpcResponse?.profile as? [String: String]), profile)
    let expiresIn = try XCTUnwrap(rpcResponse?.approximateExpirationDate?.timeIntervalSinceNow)
    XCTAssertEqual(expiresIn, 12345, accuracy: 0.1)
    XCTAssertEqual(rpcResponse?.providerID, kTestProviderID)
    XCTAssertFalse(try XCTUnwrap(rpcResponse?.isNewUser))
  }

  private func convertToJson(_ input: AnyHashable) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: input)
    return String(decoding: data, as: UTF8.self)
  }

  private func makeVerifyAssertionRequest() -> VerifyAssertionRequest {
    let request = VerifyAssertionRequest(providerID: kTestProviderID,
                                         requestConfiguration: makeRequestConfiguration())
    request.providerAccessToken = kTestProviderAccessToken
    return request
  }
}
