RSpec.describe APIDocumentationHelpers do
  describe "operationId" do
    let(:documentation) do
      Class.new(RSpec::Core::ExampleGroup) do
        extend Rswag::Specs::ExampleGroupHelpers
        extend APIDocumentationHelpers
      end
    end

    {
      "a GET endpoint without an API version" => [:get, "/api/hello/world", "getWorld"],
      "a GET collection endpoint with an API version" => [:get, "/api/induction/v1/teachers", "getTeachers"],
      "a GET collection endpoint with a multi-digit API version" => [:get, "/api/induction/v12/teachers", "getTeachers"],
      "a GET member endpoint with a path parameter" => [:get, "/api/induction/v1/teachers/{id}", "getTeacher"],
      "a GET member endpoint with a hyphenated resource name" => [:get, "/api/induction/v1/appropriate-bodies/{id}", "getAppropriateBody"],
      "a POST collection endpoint" => [:post, "/api/induction/v1/teachers", "postTeacher"],
      "a POST member action using the action name instead of the HTTP method" => [:post, "/api/induction/v1/teachers/{teacher_trn}/claim", "claimTeacher"],
      "a nested POST collection endpoint using singular parent and child names" => [:post, "/api/training/v4/teachers/{trn}/participant-declarations", "postTeacherParticipantDeclaration"],
      "a nested GET member endpoint using singular parent and child names" => [:get, "/api/training/v4/teachers/{teacher_trn}/declarations/{declaration_id}", "getTeacherDeclaration"],
      "a nested GET collection endpoint using a singular parent and plural child name" => [:get, "/api/training/v4/teachers/{teacher_trn}/declarations", "getTeacherDeclarations"],
      "a nested DELETE member endpoint using singular parent and child names" => [:delete, "/api/training/v4/teachers/{teacher_trn}/declarations/{declaration_id}", "deleteTeacherDeclaration"],
      "a nested POST member action including both parent and child names" => [:post, "/api/induction/v1/teachers/{teacher_trn}/declarations/{declaration_id}/void", "voidTeacherDeclaration"],
    }.each do |description, (method, path, operation_id)|
      it "generates #{operation_id} for #{description}" do
        documentation.document_api(method => path) {}

        operation = documentation.children.first.children.first.metadata[:operation]
        expect(operation[:operationId]).to eq(operation_id)
      end
    end
  end
end
