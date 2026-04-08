RSpec.describe WizardStoreRescuable, type: :controller do
  controller(ApplicationController) do
    include WizardStoreRescuable

    before_action :assign_wizard

    def index
      raise ApplicationWizardStep::StoreEmptyError
    end

  private

    def assign_wizard
      @wizard = self.class.test_wizard
    end
  end

  before do
    stub_const("FakeWizard", Struct.new(:first_step_path))
    controller.class.singleton_class.attr_accessor :test_wizard
    controller.class.test_wizard = FakeWizard.new("/wizard/start")

    routes.draw { get "index" => "anonymous#index" }
  end

  it "rescues StoreEmptyError and redirects to the wizard's first step" do
    get :index

    expect(response).to redirect_to("/wizard/start")
  end

  it "sets the empty-store flash alert" do
    get :index

    expect(flash[:alert]).to eq(ApplicationWizardStep::STORE_EMPTY_FLASH_MESSAGE)
  end

  it "lets unrelated exceptions propagate" do
    allow(controller).to receive(:index).and_raise(ArgumentError, "boom")

    expect { get :index }.to raise_error(ArgumentError, "boom")
  end
end
