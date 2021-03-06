require 'spec_helper'

describe ControlVariableBuilder do
  let(:simulator_instance) { create(:simulator_instance) }
  let(:cv_builder) { ControlVariableBuilder.new(simulator_instance) }
  let(:validated_data) do
    {
      'features' => { 'featureA' => 34.0 },
      'extended_features' => {
        'featureB' => [37, 38],
        'featureC' => {
          'C1' => 40.0, 'C2' => 42.0
        }
      },
      'symmetry_groups' => [
        {
          'role' => 'Role1',
          'strategy' => 'Strategy1',
          'players' => [
            {
              'payoff' => 2992.73,
              'features' => {
                'featureA' => 0.001
              },
              'extended_features' => {
                'featureB' => [2.0, 2.1]
              }
            }
          ]
        },
        {
          'role' => 'Role2',
          'strategy' => 'Strategy2',
          'players' => [
            {
              'payoff' => 2929.34,
              'features' => {
                'featureA' => 0.001,
                'featureB' => 23
              }
            },
            {
              'payoff' => 2000.00,
              'features' => { 'featureA' => 0.96 }
            }
          ]
        }
      ]
    }
  end

  describe '#extract_control_variables' do
    it 'creates a new control variable for each unique entry' do
      simulator_instance.simulator.add_role('Role1')
      simulator_instance.simulator.add_role('Role2')
      cv_builder.extract_control_variables(validated_data)
      expect(ControlVariable.count).to eq(1)
      expect(ControlVariable.first.name).to eq('featureA')
      expect(ControlVariable.first.role_coefficients.pluck(:role).sort)
        .to eq(%w(Role1 Role2))
      expect(PlayerControlVariable.count).to eq(3)
      expect(PlayerControlVariable.where(
        simulator_instance_id: simulator_instance.id, name: 'featureA',
        role: 'Role1').count).to eq(1)
      expect(PlayerControlVariable.where(
        simulator_instance_id: simulator_instance.id, name: 'featureA',
        role: 'Role2').count).to eq(1)
      expect(PlayerControlVariable.where(
        simulator_instance_id: simulator_instance.id, name: 'featureB',
        role: 'Role2').count).to eq(1)
    end
  end
end
