require "httparty"

# Public: Main class for interacting with the Adyen API
#
# Use an instance to configure for the situation and talk to the API.
class AdyenClient
  include HTTParty

  ADYEN_API_VERSION = "v30"
  # Internal: Access the configuration instance.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Public: Configure the AdyenClient class.
  #
  # hash   - The configuration to apply. Will be evaluated before &block. (optional if &block is given)
  # &block - Yields the configuration instance. (optional if hash is given)
  #
  # Examples
  #
  #   # Block style
  #   AdyenClient.configure do |c|
  #     c.environment = :test
  #     c.username = "ws_123456@Company.FooBar"
  #     c.password = "correctbatteryhorsestaple"
  #     c.cse_public_key = "10001|..."
  #     c.default_merchant_account = "FooBar123"
  #     c.default_currency = "EUR"
  #   end
  #
  #   # Hash style works too, string or symbol keys
  #   AdyenClient.configure(environment: :test, username: "ws_123456@Company.FooBar", ...)
  #
  #   # That comes in handy to configure the client from a YAML file
  #   AdyenClient.configure(YAML.load_file(Rails.root.join("config", "adyen.yml"))[Rails.env.to_s])
  #
  #   # You can override all default options for each instance of a client
  #   client = AdyenClient.new(merchant_account: "FooBarSubMerchant123")
  #   eur_client = AdyenClient.new(currency: "EUR")
  #
  # Yields the configuration singleton.
  #
  # Returns the configuration singleton.
  def self.configure(hash = nil)
    configuration.set(hash) if hash
    yield configuration if block_given?
    configuration.apply(self)
    configuration
  end

  # Public: Returns an ISO8601 formatted datetime string used in Adyens generationTime.
  def self.generation_time
    Time.now.iso8601
  end

  # Public: Returns the configured CSE (client side encryption) public key.
  def self.cse_public_key
    configuration.cse_public_key
  end

  attr_reader :merchant_account

  # Public: Initializes a new instance of the AdyenClient.
  #         You can override merchant_account and currency from the default configuration.
  #
  # :merchant_account - Sets the default_merchant_account for this instance. (optional)
  # :currency         - Sets the default_currency for this instance. (optional)
  # :response_class   - Use a custom class for handling responses from Adyen. (optional)
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def initialize(merchant_account: configuration.default_merchant_account, currency: configuration.default_currency, response_class: Response)
    @merchant_account = merchant_account
    @currency = currency
    @response_class = response_class
  end

  # Public: Charge a user by referencing his stored payment method.
  #
  # :shopper_reference   - The user reference id from your side.
  # :amount              - The amount to charge in cents.
  # :reference           - Your reference id for this transaction.
  # :recurring_reference - Use when referencing a specific payment method stored for the user. (default: "LATEST")
  # :merchant_account    - Use a specific merchant account for this transaction. (default: set by the instance or configuration default merchant account)
  # :currency            - Use a specific 3-letter currency code. (default: set by the instance or configuration default currency)
  # :statement           - Supply a statement that should be shown on the customers credit card bill. (default: "")
  #                        Note however that most card issues allow for not more than 22 characters.
  # :recurring_processing_model - Added in v30 of the Adyen API and required by Visa as of April 2018. One of "Subscription" or "CardOnFile". Defaults to "CardOnFile").
  #
  # Returns an AdyenClient::Response or your specific response implementation.
def authorise_recurring_payment(reference:, shopper_reference:, amount:, recurring_reference: "LATEST", merchant_account: @merchant_account, currency: @currency, statement: "", recurring_processing_model: "CardOnFile")
    unless %w(Subscription CardOnFile).include?(recurring_processing_model)
      raise ArgumentError, 'invalid recurring_processing_model'
    end
    postJSON("/Payment/#{ADYEN_API_VERSION}/authorise",
      reference: reference,
      amount: { value: amount, currency: currency },
      merchantAccount: merchant_account,
      shopperReference: shopper_reference,
      shopperStatement: statement,
      selectedRecurringDetailReference: recurring_reference,
      selectedBrand: "",
      recurring: { contract: "RECURRING" },
      shopperInteraction: "ContAuth",
      recurringProcessingModel: recurring_processing_model
    )
  end
  alias_method :authorize_recurring_payment, :authorise_recurring_payment

  # Public: List the stored payment methods for a user.
  #
  # :shopper_reference   - The user reference id from your side.
  # :merchant_account    - Use a specific merchant account for this transaction. (default: set by the instance or configuration default merchant account)
  # :currency            - Use a specific 3-letter currency code. (default: set by the instance or configuration default currency)
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def list_recurring_details(shopper_reference:, merchant_account: @merchant_account, contract: "RECURRING")
    postJSON("/Recurring/#{ADYEN_API_VERSION}/listRecurringDetails",
      shopperReference: shopper_reference,
      recurring: { contract: contract },
      merchantAccount: merchant_account
    )
  end

  # Public: Store a payment method on a reference id for recurring/later use.
  #         Does verify the users payment method, but does not create a charge.
  #
  # :encrypted_card    - The encrypted credit card information generated by the CSE (client side encryption) javascript integration.
  # :reference         - Your reference id for this transaction.
  #                      Caveat: According to Adyen a hyphen "-" is treated as a separator for multiple references.
  #                      If you are using something like `SecureRandom.uuid` be sure to replace "-" with something else.
  # :shopper           - The hash describing the shopper for this contract:
  #                     :reference - Your reference id for this shopper/user. (mandatory)
  #                     :email     - The shoppers email address. (optional but recommended)
  #                     :ip        - The shoppers last known ip address. (optional but recommended)
  # :merchant_account  - Use a specific merchant account for this transaction. (default: set by the instance or configuration default merchant account)
  # :currency          - Use a specific 3-letter currency code. (default: set by the instance or configuration default currency)
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def create_recurring_contract(encrypted_card:, reference:, shopper:, merchant_account: @merchant_account, currency: @currency)
    postJSON("/Payment/#{ADYEN_API_VERSION}/authorise",
      reference: reference,
      additionalData: { "card.encrypted.json": encrypted_card },
      amount: { value: 0, currency: currency },
      merchantAccount: merchant_account,
      shopperEmail: shopper[:email],
      shopperIP: shopper[:ip],
      shopperReference: shopper[:reference],
      recurring: { contract: "RECURRING" }
    )
  end

  # Public: Charge a credit card.
  #
  # :encrypted_card   - The encrypted credit card information generated by the CSE (client side encryption) javascript integration.
  # :amount           - The integer amount in cents.
  # :reference        - Your reference id for this transaction.
  #                     Caveat: According to Adyen a hyphen "-" is treated as a separator for multiple references.
  #                     If you are using something like `SecureRandom.uuid` be sure to replace "-" with something else.
  # :merchant_account - Use a specific merchant account for this transaction. (default: set by the instance or configuration default merchant account)
  # :currency         - Use a specific 3-letter currency code. (default: set by the instance or configuration default currency)
  # :shopper          - The hash describing the shopper for this transaction, optional but recommended (default: {}):
  #                     :email     - The shoppers email address (optional but recommended).
  #                     :ip        - The shoppers last known ip address (optional but recommended).
  #                     :reference - Your reference id for this shopper/user (optional).
  # :statement        - Supply a statement that should be shown on the customers credit card bill. (default: "")
  #                     Note however that most card issues allow for not more than 22 characters.
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def authorise(encrypted_card:, amount:, reference:, merchant_account: @merchant_account, currency: @currency, shopper: {}, statement: "")
    postJSON("/Payment/#{ADYEN_API_VERSION}/authorise",
      reference: reference,
      amount: { value: amount, currency: currency },
      merchantAccount: merchant_account,
      additionalData: { "card.encrypted.json": encrypted_card },
      shopperEmail: shopper[:email],
      shopperIP: shopper[:ip],
      shopperReference: shopper[:reference],
      shopperStatement: statement
    )
  end
  alias_method :authorize, :authorise

  # Public: Verify a credit card (does not create a charge, but may be verified for a specified amount).
  #
  # :encrypted_card   - The encrypted credit card information generated by the CSE (client side encryption) javascript integration.
  # :reference        - Your reference id for this transaction.
  #                     Caveat: According to Adyen a hyphen "-" is treated as a separator for multiple references.
  #                     If you are using something like `SecureRandom.uuid` be sure to replace "-" with something else.
  # :amount           - The integer amount in cents. Will not be charged on the card. (default: 0)
  # :merchant_account - Use a specific merchant account for this transaction (default: set by the instance or configuration default merchant account).
  # :currency         - Use a specific 3-letter currency code (default: set by the instance or configuration default currency).
  # :shopper          - The hash describing the shopper for this transaction, optional but recommended (default: {}):
  #                     :email     - The shoppers email address (optional but recommended).
  #                     :ip        - The shoppers last known ip address (optional but recommended).
  #                     :reference - Your reference id for this shopper/user (optional).
  # :statement        - Supply a statement that should be shown on the customers credit card bill. (default: "")
  #                     Note however that most card issues allow for not more than 22 characters.
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def verify(encrypted_card:, reference:, amount: 0, merchant_account: @merchant_account, currency: @currency, shopper: {}, statement: "")
    postJSON("/Payment/#{ADYEN_API_VERSION}/authorise",
      reference: reference,
      amount: { value: 0, currency: currency },
      additionalAmount: { value: amount, currency: currency },
      merchantAccount: merchant_account,
      additionalData: { "card.encrypted.json": encrypted_card },
      shopperEmail: shopper[:email],
      shopperIP: shopper[:ip],
      shopperReference: shopper[:reference],
      shopperStatement: statement
    )
  end

  # Public: Cancels a credit card transaction.
  #
  # :original_reference   - The psp_reference from Adyen for this transaction.
  # :reference            - Your reference id for this transaction.
  # :modification_amount  - The amount to capture.
  #                         :currency   - Must match currency used in authorisation request.
  #                         :value      - Must be smaller than or equal to the authorised amount.
  # :merchant_account     - Use a specific merchant account for this transaction (default: set by the instance or configuration default merchant account).
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def capture(original_reference:, reference:, modification_amount:, merchant_account: @merchant_account)
    postJSON("/Payment/#{ADYEN_API_VERSION}/capture",
      reference: reference,
      merchantAccount: merchant_account,
      modificationAmount: modification_amount,
      originalReference: original_reference
    )
  end

  # Public: Cancels a credit card transaction.
  #
  # :original_reference - The psp_reference from Adyen for this transaction.
  # :reference          - Your reference id for this transaction.
  # :merchant_account   - Use a specific merchant account for this transaction (default: set by the instance or configuration default merchant account).
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def cancel(original_reference:, reference:, merchant_account: @merchant_account)
    postJSON("/Payment/#{ADYEN_API_VERSION}/cancel",
      reference: reference,
      merchantAccount: merchant_account,
      originalReference: original_reference
    )
  end

  # Public: Refunds a credit card transaction.
  #
  # :original_reference - The psp_reference from Adyen for this transaction.
  # :amount             - The amount in cents to be refunded.
  # :reference          - Your reference id for this transaction.
  # :merchant_account   - Use a specific merchant account for this transaction (default: set by the instance or configuration default merchant account).
  # :currency           - Use a specific 3-letter currency code (default: set by the instance or configuration default currency).
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def refund(original_reference:, amount:, reference:, merchant_account: @merchant_account, currency: @currency)
    postJSON("/Payment/#{ADYEN_API_VERSION}/refund",
      reference: reference,
      merchantAccount: merchant_account,
      modificationAmount: { value: amount, currency: currency },
      originalReference: original_reference
    )
  end

  # Public: Cancels or refunds a credit card transaction. Use this if you don't know the exact state of a transaction.
  #
  # :original_reference - The psp_reference from Adyen for this transaction.
  # :reference          - Your reference id for this transaction.
  # :merchant_account   - Use a specific merchant account for this transaction (default: set by the instance or configuration default merchant account).
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def cancel_or_refund(original_reference:, reference:, merchantAccount: @merchant_account)
    postJSON("/Payment/#{ADYEN_API_VERSION}/cancelOrRefund",
      reference: reference,
      merchantAccount: merchant_account,
      originalReference: original_reference
    )
  end

  # Public: Initiate Payout to an external bank. This class contains data that
  #         should be passed in the /storeDetailAndSubmitThirdParty request to
  #         initiate a payout.
  # !! Important note: you need a special Adyen webservice user for this operation
  #
  # :reference          - Your reference id for this transaction.
  # :amount             - The amount to payout in cents, Hash with value and currency
  # :bank               - Bank information, Hash with
  #            :bankName      - Name of the bank
  #            :bic           - BIC (Swift)
  #            :iban          - IBAN
  #            :countryCode   - Country code where the bank is located.
  #            :bankCity      - Name of the bank
  #            :ownerName     - The name of the bank account holder. Non Latin letters get converted
  #            :bankCity      - The bank city
  #            :taxId         - The bank account holder's tax ID
  # :receiver            - Receiver is the person who gets the money (called shopper in Adyen), Hash with
  #            :email         - The receivers's email address
  #            :reference     - The receivers's reference for the payment transaction
  #            :firstName     - The first name
  #            :lastName      - The last name
  #            :gender        - The following values are permitted: MALE, FEMALE, UNKNOWN
  #            :dateOfBirth   - BIC (Swift)
  #            :nationality   - The receivers's nationality
  # :billingAddress      - billing address
  #            :houseNumber   - The number (or name) of the house
  #            :street        - The name of the street
  #            :city          - The name of the city
  #            :stateOrProvince - The abbreviation of the state or province
  #            :country       - The two-character country code of the address
  #            :postalCode    - The postal code
  # :merchant_account   - Use a specific merchant account for this transaction (default: set by the instance or configuration default merchant account).
  #
  # Returns an StoreDetailAndSubmitResponse
  # If the message is syntactically valid and merchantAccount is correct, you receive a payout-submit-received response with the following fields:
  # @see https://docs.adyen.com/api-explorer/#/Payout/v30/storeDetailAndSubmitThirdParty
  def initiate_payout(reference:,
                        amount: {
                          value: 0,
                          currency: @currency
                        },
                        bank: {},
                        receiver: {},
                        billingAddress: {},
                        merchantAccount: @merchant_account)
    postJSON("/Payout/#{ADYEN_API_VERSION}/storeDetailAndSubmitThirdParty",
      merchantAccount: @merchant_account,
      amount: {
        value: amount[:value],
        currency: amount[:currency]
      },
      recurring: {
          contract: "RECURRING,PAYOUT"
      },
      reference: reference,
      bank: {
          bankName: bank[:bankName],
          bic: bank[:bic],
          countryCode: bank[:countryCode],
          iban: bank[:iban],
          ownerName: bank[:ownerName],
          bankCity: bank[:bankCity],
          taxId: bank[:taxId]
      },
      shopperEmail: receiver[:email],
      shopperReference: receiver[:reference],
      shopperName: {
          firstName: receiver[:firstName],
          lastName: receiver[:lastName],
          gender: receiver[:gender]
      },
      dateOfBirth: receiver[:dateOfBirth],
      entityType: "Person", #"Company"
      nationality: receiver[:nationality],
      billingAddress: {
          houseNumberOrName: billingAddress[:houseNumber],
          street: billingAddress[:street],
          city: billingAddress[:city],
          stateOrProvince: billingAddress[:stateOrProvince],
          country: billingAddress[:country],
          postalCode: billingAddress[:postalCode]
      }
    )
  end


  # Public: ConfirmPayout. Confirms a previously initated payout
  #
  # !! Important note: you need a special Adyen webservice user for this operation.
  #                    It is NOT the same as for initiating the payout
  #
  # :original_reference - The psp_reference from Adyen for this transaction.
  # :merchant_account   - Use a specific merchant account for this transaction (default: set by the instance or configuration default merchant account).
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def confirm_payout(original_reference:, merchantAccount: @merchant_account)
    postJSON("/Payout/#{ADYEN_API_VERSION}/confirmThirdParty",
      merchantAccount: merchant_account,
      originalReference: original_reference
    )
  end

  # Internal: Send a POST request to the Adyen API.
  #
  # path - The Adyen JSON API endpoint path.
  # data - The Hash describing the JSON body for this request.
  #
  # Returns an AdyenClient::Response or your specific response implementation.
  def postJSON(path, data)
    response = self.class.post(path, body: data.to_json)
    @response_class ? @response_class.parse(response) : response
  end

  # Internal: Returns the AdyenClient configuration singleton
  def configuration
    self.class.configuration
  end

end

require "adyen_client/utils"
require "adyen_client/response"
require "adyen_client/configuration"
