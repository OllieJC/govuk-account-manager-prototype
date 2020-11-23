RSpec.describe "/account/confirmation" do
  let(:user) { FactoryBot.create(:user) }

  it "creates a job to activate any email subscriptions" do
    get user_confirmation_path(confirmation_token: user.confirmation_token)
    assert_enqueued_jobs 1, only: ActivateEmailSubscriptionsJob
  end

  context "with a logged-in user" do
    before { sign_in user }

    it "shows the confirmation reminder" do
      get user_root_path
      expect(response.body).to have_selector(
        "a[href=\"#{new_user_confirmation_path}\"]",
        text: I18n.t("confirm.link_text"),
      )
    end

    it "hides the reminder after confirmation" do
      get user_confirmation_path(confirmation_token: user.confirmation_token)
      get user_root_path
      expect(response.body).to_not have_content(I18n.t("confirm.link_text"))
    end
  end
end
