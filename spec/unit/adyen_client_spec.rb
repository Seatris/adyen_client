require "securerandom"
require_relative "../spec_helper.rb"

describe AdyenClient, vcr: { per_group: true } do
  # These encrypted card strings are taken form the client_side_encryption.html example in the root of the project directory
  let(:encrypted_card) { "adyenjs_0_1_15$NZcG1Vlfm6+9wygEzXFEjTCQ1go1RophriLC3DvvGKX5HH+3tI4q/xhZ9j6THxEHgbDrQoQFSjkxVJvteCkExFgnwKjRCJKH8M9AfOj4abyO/HQkJ+wR9rnVPxAeBHvHkkcYN0vJ4BxqqE+MX1cJjTvj15B/hKc6K1RNqNLg3h1aQas55GVxsYDT9pZM+ywMMY/rmhw0JcsbfJL17ui1fmwQCIMT0uOvWtWSP+OVYXoLYjlzEszWieIdip9ZCEhFIaK6dgsoPWwTu67mmWU+7EjwDDMmjMrzctcf5Q4Ofkx066bWULiYtAZjvkrdh67X5Ff13pVG0+gXMy5EaxJQGg==$lmXl2HmmBshGyG2Vs1NxQnJB/YGIwfNfvYjTkQUXxDkJOSkTAPc/cmmpJTgaNbwC7jGN/3qHfwGHt20IvipVpi9Q2ZIz0JOuQ2KPQtD3GG4xOTy1+KqJFFl8hiD055MoLxY8saeR51YybmVGK8xLwwow4Dce7InkD5x7rNXOrwQV6KErR0ZLzE2vU6ulKOg156XhSXaI3wjPJXRdI47+JaVvaulmz6drPZXaXXeEA7w0qfgDCNqD0FoyyxNV5h7g5qiRl0shmXGggCNWzPzdhPUQ0+WgOYcGGaxsZyEVXloRNjhU2rK9YnM4Xw04pekPFfNjvMcMpDmXAf8nQ4xXZnmwq7oAG2KQLmL4Bw5JxX4PC65kyVc=" }
  let(:encrypted_card_wrong_cvc) { "adyenjs_0_1_15$h+rrBTrmDZSaaMXHPp08TH+1vz0Be/aS67H/NromtRwaReG4V8PDJG/xfHCVlHo6lZ63BhiZtzGV99rIuFB0tcdDVofGAuoEHoXFAlyaRb6aV8zt3ckNt9CPmeAaWNoRCACPPMba2I013Dut3Gn3KwDeBz08Wue/zUr4TQEIM84pprsJhKe2vkvcy0CLMuVkFCwxICYLehLIHVTN0hqJ/fZcq+cn+SW9DbZzIy+Ked5++UAuAnuVmvMVx2AjogswwG5TilIBdZGRHIJdkFzRrs+hl3h2vOkpfTUuYC38BUwUeaKcz3YpR3VypH8pL/MI47h2nwfCAIW1ZedD+0W9xQ==$I760jRxGuDXWUQHAUvh5psvn1VnC1/KsHbRbW8jRqu4DOMv/rtQGGdb7J3sl9h+tCIdad9/kpIoyt8TzRHk+3zcZjCygKL8iQ7EN97TGrCPOyytRW2qEngR6wB2H/Qxc1+bF0B+FswFzuJLgfZJZ1Uy92oKL4a+ZOt1WMvYv9ppwjP1kPSplxhWbUIDvvFfaoBHa61aFkb3BMu0yshTjATw4kkJlfKBdru3IotQrimRZsGFCcUJV/JPbJLjbb83qRqtpub+oax7+GM9ZLw1wBOz2744y7784sk0m30EivV/dxQUfFBnkD0GGXyz0+vdcphy60DyzH0h2rbWDdMt1V1v1AVSNlygIOL+d3Cri8tYpf7kjXUlko/wB0sgjecv1Ux/CrlI9XQ==" }
  let(:encrypted_card_wrong_exp) { "adyenjs_0_1_15$ejfUxXsas1eqSSCPpZgs5AftI7VMJm9GvgXkCUa1mzuM9ZIZghLO/wYvP18eyOht/ukzR/DewYdlG9NGuk6jJewyzjJEDOY+vtbovMY90z2LfQlGDRCIXqvgjfLopSrXw22MGYiUgGvqNcZAO5CIkOucLXeObYKmEq97w/+qEwx7AJMIJQtOA/BDLdwEm23lLeWoHXs8CDE7aDGi4OLlrxp/lPfnfUbmPHNynlxx1cNwmqqTGSOq+zAuQr6KLSo5DGN483UsyjfXJtt2sgi2/CkPv3ZE8zHlWkx5Hrgt8/FKsvmU7NDv+YMu9w8uSML7OQEUkC9EixVHdpEp701whw==$THHVc01/56Mus1aJ5Vpb2RC1A1cmAe4RGJ7voYYS9D3oyXPez7okCC6nxT0ovLvsnySLOH1+LBiA8KZjkpogoulevyquICIMrbngIAv5Z2D8+QnrJ13XChvXJ7dtD4fW1o88WLZerxwReObCsGsizx3Fw0rhu8RowFy22ftDUHc2D4D2IAm9hXgt8PQmQx4ehCCUjXTVF8yEhPuHpA10xnbc3xRRKZrsGwwGi7Fl90bgVPT+dpVO1v0nlWM5Gr5Ji07Bmz5N1s5X4MJHs/stNe5ePzRDqI2dlkqOrY6cnDcARwxnT9TCfb3hVGsfYxoNgKOTBtyunhDOTfrhoMr8QxcxdxfPcH5VWSpMildt5BSfE3Hbuw4c3jVGHJrlTzx91LWMVwrr6w==" }
  let(:encrypted_card_garbled) { encrypted_card.gsub(/[abc]/, "x") }
  let(:shopper) { Hash[email: "john@doe.com", ip: "127.0.0.1", reference: "john"] }
  let(:client) { AdyenClient.new }

  # very helpful when running tests against the live api
  # using it produces early failures showing the errors
  def assert_no_errors_in_response
    assert_equal [nil, nil], response.data.values_at("error_type", "message")
  end

  describe "#verify" do
    describe "authorised" do
      let(:response) { client.verify(amount: 123, encrypted_card: encrypted_card, reference: SecureRandom.uuid) }
      before { assert_no_errors_in_response }

      it "should return an authorised response with valid data" do
        assert response.authorised?
      end

      it "should include the psp_reference in the response" do
        # taken from spec/cassettes/AdyenClient/verify/successful.yml
        assert_equal "8815312278659725", response.psp_reference # taken from vcr cassette
      end
    end

    describe "refused" do
      let(:response) { client.verify(amount: 123, encrypted_card: encrypted_card_wrong_cvc, reference: SecureRandom.uuid) }

      it "should not be authorised" do
        assert ! response.authorised?
      end

      it "should have a refusal reason" do
        assert_equal "CVC Declined", response.refusal_reason
      end
    end
  end

  describe "#authorise" do
    describe "authorised" do
      let(:response) { client.authorise(amount: 123, encrypted_card: encrypted_card, reference: SecureRandom.uuid) }
      before { assert_no_errors_in_response }

      it "should return an authorised response" do
        assert response.authorised?
      end

      it "should include the psp_reference in the response" do
        assert_equal "8835312278663525", response.psp_reference # taken from vcr cassette
      end
    end

    describe "refused" do
      let(:response) { client.authorise(amount: 123, encrypted_card: encrypted_card_wrong_cvc, reference: SecureRandom.uuid) }

      it "should not be authorised" do
        assert ! response.authorised?
      end

      it "should have a refusal reason" do
        assert_equal "CVC Declined", response.refusal_reason
      end
    end
  end

  describe "#capture" do
  end

  describe "#cancel" do
  end

  describe "#refund" do
  end

  describe "#cancel_or_refund" do
  end

  describe "#create_recurring_contract" do
    describe "authorised" do
      let(:response) { client.create_recurring_contract(encrypted_card: encrypted_card, shopper: shopper, reference: SecureRandom.uuid) }
      before { assert_no_errors_in_response }

      it "should return an authorised response" do
        assert response.authorised?
      end

      it "should include the psp_reference in the response" do
        assert_equal "8815312278689953", response.psp_reference # taken from vcr cassette
      end
    end
  end

  describe "#list_recurring_details" do
    let(:response)  { client.list_recurring_details(shopper_reference: shopper[:reference]) }
    let(:contract) { response.details.first }

    it "should return a response with the shopper_reference" do
      assert_equal shopper[:reference], response.shopper_reference
    end

    it "should return a contract with a recurring detail reference" do
      assert_equal "8314508657181050", contract["recurring_detail_reference"]
    end
  end

  describe "#authorise_recurring_payment" do
    describe "authorised" do
      let(:response) { client.authorise_recurring_payment(amount: 456, reference: SecureRandom.uuid, shopper_reference: shopper[:reference]) }
      before { assert_no_errors_in_response }

      it "should return an authorised response" do
        assert response.authorised?
      end

      it "should include the psp_reference in the response" do
        assert_equal "8825312278673617", response.psp_reference # taken from vcr cassette
      end
    end
  end

  describe '#payout' do
    let(:response)  { client.initiate_payout(
        reference: 'August2018PayoutForFoo',
        receiver: {
          email: "shopper@email.com",
          reference: "TheShopperReference",
          firstName: "Adyen",
          lastName: "MALE",
          gender: "Test",
          dateOfBirth: "1990-01-01",
          nationality: "NL"
        },
        bank: {
          bankName: "AbnAmro",
          bic: "ABNANL2A",
          countryCode: "NL",
          iban: "NL32ABNA0515071439",
          ownerName: "Adyen",
          bankCity: "Amsterdam",
          taxId:"bankTaxId"
        },
        amount: {
          value: 2099,
          currency: "EUR"
        },
        billingAddress: {
          houseNumber: "17",
          street: "Teststreet 1",
          city: "Amsterdam",
          stateOrProvince: "NY",
          country: "US",
          postalCode: "12345"
        }
      )
    }
    before { assert_no_errors_in_response }

    it "should include the psp_reference in the response" do
      assert_equal "8515324297411387", response.psp_reference # taken from vcr cassette
    end
  end

  describe '#confirm payout' do
    let(:response)  { client.confirm_payout(original_reference: '8515324297411387')
    }

    before { assert_no_errors_in_response }

    it "should include the psp_reference in the response" do
      assert_equal "8815324304179602", response.psp_reference # taken from vcr cassette
    end
  end
end
