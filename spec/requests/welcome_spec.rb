RSpec.describe "welcome" do
  describe "GET" do
    it "renders the welcome page" do
      get welcome_path

      expect(response.body).to have_content(I18n.t("welcome.heading"))
    end
  end

  context "the user is logged in" do
    let(:user) { FactoryBot.create(:user) }

    before do
      sign_in(user)
    end

    it "redirects the user to the account page" do
      get welcome_path

      expect(response).to redirect_to(user_root_path)
    end
  end
end
