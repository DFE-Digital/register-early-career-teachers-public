RSpec.describe "Admin::DataFixesController" do
  before do
    allow(Rails.application.config)
      .to receive(:enable_admin_data_fixes)
      .and_return(enable_admin_data_fixes)
  end

  describe "GET #new" do
    subject do
      get path_for_step("csv")
      response
    end

    context "when `enable_admin_data_fixes` is true" do
      let(:enable_admin_data_fixes) { true }

      context "when not signed in" do
        it { is_expected.to redirect_to(sign_in_path) }
      end

      context "when signed in as a non-DfE user" do
        include_context "sign in as non-DfE user"

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context "when signed in as a non-product DfE user" do
        include_context "sign in as DfE user"

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context "when signed in as a product team user" do
        include_context "sign in as product_team DfE user"

        it { is_expected.to have_http_status(:ok) }
      end
    end

    context "when `enable_admin_data_fixes` is false" do
      let(:enable_admin_data_fixes) { false }

      context "when not signed in" do
        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a non-DfE user" do
        include_context "sign in as non-DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a non-product DfE user" do
        include_context "sign in as DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a product team user" do
        include_context "sign in as product_team DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end
    end
  end

  describe "POST #create" do
    subject do
      post(path_for_step("csv"), params: csv_params)
      response
    end

    let(:csv_params) { { csv: { csv_string: } } }
    let(:csv_string) do
      <<~ROWS
        object_type,object_id,action,attributes
        something,1,create,"attribute1,value1,attribute2,value2"
        another_thing,2,destroy,""
      ROWS
    end

    context "when `enable_admin_data_fixes` is true" do
      let(:enable_admin_data_fixes) { true }

      context "when not signed in" do
        it { is_expected.to redirect_to(sign_in_path) }
      end

      context "when signed in as a non-DfE user" do
        include_context "sign in as non-DfE user"

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context "when signed in as a non-product DfE user" do
        include_context "sign in as DfE user"

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context "when signed in as a product team user" do
        include_context "sign in as product_team DfE user"

        let(:teacher) { FactoryBot.create(:teacher, trn: "123456") }
        let(:other_teacher) { FactoryBot.create(:teacher, trn: "234567") }

        context "when the CSV is valid and changes can be processed" do
          let(:csv_string) do
            <<~ROWS
              object_type,object_id,action,attributes
              Teacher,#{teacher.id},update,"trn,345678"
              Teacher,#{other_teacher.id},update,"trn,456789"
            ROWS
          end

          it "redirects to preview step, then redirects to verify step " \
             "and persists changes after verification" do
            expect(subject).to redirect_to(path_for_step("preview"))
            follow_redirect!

            expect { post path_for_step("preview") }
              .to not_change { teacher.reload.trn }
              .and(not_change { other_teacher.reload.trn })

            expect(response).to redirect_to(path_for_step("verify"))
            follow_redirect!

            expect { post path_for_step("verify") }
              .to change { teacher.reload.trn }.from("123456").to("345678")
              .and change { other_teacher.reload.trn }.from("234567").to("456789")
          end

          context "but there is an unexpected error" do
            before do
              processor = Admin::DataFixes::Processor.new
              allow(Admin::DataFixes::Processor)
                .to receive(:new)
                .and_return(processor)
              allow(processor)
                .to receive(:process!)
                .with(data_change: {
                  "object_type" => "Teacher",
                  "object_id" => teacher.id.to_s,
                  "action" => "update",
                  "attributes" => "trn,345678"
                })
                .and_call_original
              allow(processor)
                .to receive(:process!)
                .with(data_change: {
                  "object_type" => "Teacher",
                  "object_id" => other_teacher.id.to_s,
                  "action" => "update",
                  "attributes" => "trn,456789"
                })
                .and_raise(StandardError, "oops")
            end

            it "redirects to preview step, then raises the unexpected error " \
               "without persisting any changes" do
              expect(subject).to redirect_to(path_for_step("preview"))

              follow_redirect!

              expect { post path_for_step("preview") }
                .to raise_error(StandardError, "oops")
                .and not_change { teacher.reload.trn }
                .and(not_change { other_teacher.reload.trn })
            end
          end
        end

        context "when the CSV is valid but the changes cannot be processed" do
          let(:csv_string) do
            <<~ROWS
              object_type,object_id,action,attributes
              Teacher,#{teacher.id},update,"trn,123"
            ROWS
          end

          it "redirects to preview step, then returns unprocessable_content" do
            expect(subject).to redirect_to(path_for_step("preview"))

            follow_redirect!

            expect { post path_for_step("preview") }
              .not_to(change { teacher.reload.trn })

            expect(response).to have_http_status(:unprocessable_content)
          end
        end

        context "when the CSV is invalid" do
          let(:csv_string) do
            <<~ROWS
              object_type,object_id,attributes
              something,1,create,"attribute1,value1,attribute2,value2"
              another_thing,2,destroy,""
            ROWS
          end

          it { is_expected.to have_http_status(:unprocessable_content) }
        end
      end
    end

    context "when `enable_admin_data_fixes` is false" do
      let(:enable_admin_data_fixes) { false }

      context "when not signed in" do
        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a non-DfE user" do
        include_context "sign in as non-DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a non-product DfE user" do
        include_context "sign in as DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end

      context "when signed in as a product team user" do
        include_context "sign in as product_team DfE user"

        it { is_expected.to have_http_status(:not_found) }
      end
    end
  end

private

  def path_for_step(step) = "/admin/data_fixes/#{step}"
end
