require 'spec_helper'

describe 'RoleManipulators' do
  let(:user) { create(:approved_user) }
  let(:token) { user.authentication_token }
  let(:role) { 'Role1' }

  shared_examples 'a RoleManipulator' do
    let(:missing_object) do
      "the #{described_class} you were looking for could not be found"
    end
    let!(:object) { create(described_class.to_s.underscore.to_sym) }
    describe "POST /api/v3/#{described_class.to_s.tableize}/:id/add_role" do
      let(:size) { 2 }
      let(:query) { { auth_token: token, role: role, count: size } }

      context "when the #{described_class} does not exist" do
        let(:url) { "/api/v3/#{described_class.to_s.tableize}/0/add_role" }
        it 'returns an appropriate 404' do
          post "#{url}.json", query
          expect(response.status).to eql(404)
          expect(response.body).to eql({ error: missing_object }.to_json)
        end
      end
      context "when the #{described_class} exists" do
        let(:url) do
          "/api/v3/#{described_class.to_s.tableize}/#{object.id}/add_role"
        end
        context 'but the role does not exist on the simulator' do
          it 'returns an appropriate 422' do
            post "#{url}.json", query
            expect(response.status).to eql(422)
            expect(response.body).to eql(
              { error: 'the Role you wished to add was not found on the' \
                " #{described_class}'s Simulator" }.to_json)
          end
        end
        context 'and the role exists on the simulator' do
          before do
            object.simulator.add_role(role)
          end
          context 'but the size is too large' do
            let(:size) { 4 }

            it 'returns the role with error message' do
              post "#{url}.json", query
              expect(response.status).to eql(422)
              expect(response.body).to eql(
                { errors:
                  { count: [
                    "can't be larger than the owner's unassigned player count"
                    ] } }.to_json)
            end
          end

          context 'and the size is acceptable' do
            it 'returns a 204 and adds the role to the game' do
              post "#{url}.json", query
              expect(response.status).to eql(204)
              expect(object.roles.where(name: role, count: size).count).to be 1
            end
          end
        end
      end
    end

    describe "POST /api/v3/#{described_class.to_s.tableize}/:id/remove_role" do
      let(:url) { "/api/v3/#{described_class.to_s.tableize}/0/remove_role" }
      let(:query) { { auth_token: token, role: role } }

      context "when the #{described_class} does not exist" do
        it 'returns an appropriate 404' do
          post "#{url}.json", query
          expect(response.status).to eql(404)
          expect(response.body).to eql({ error: missing_object }.to_json)
        end
      end
      context "when the #{described_class} exists" do
        let(:url) do
          "/api/v3/#{described_class.to_s.tableize}/#{object.id}/remove_role"
        end

        before do
          object.simulator.add_role(role)
          object.add_role(role, object.size)
        end

        it 'returns a 204 and removes the role from the game' do
          post "#{url}.json", query
          expect(response.status).to eql(204)
          expect(object.roles.where(name: role).count).to eq(0)
        end
      end
    end
  end

  describe GenericScheduler do
    it_behaves_like 'a RoleManipulator'
  end

  describe Game do
    it_behaves_like 'a RoleManipulator'
  end
end
