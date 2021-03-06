# The ControlVariableBuilder tracks the ControlVariables and
# PlayerControlVariables associated with a SimulatorInstance, and when
# observation data shows up that has previously unseen features, creates new
# ControlVariables and PlayerControlVariables to match.

class ControlVariableBuilder
  def initialize(simulator_instance)
    @instance_id = simulator_instance.id
    @roles = simulator_instance.simulator.role_configuration.keys
  end

  def extract_control_variables(data)
    control_variables(data['features'].keys, @roles)
    player_control_variables(data['symmetry_groups'])
  end

  private

  def control_variables(keys, roles)
    new_cvs(keys).map do |k|
      ControlVariable.find_or_create_by(name: k,
                                        simulator_instance_id: @instance_id)
    end
  end

  def player_control_variables(symmetry_groups)
    key_map = Hash.new { |hash, key| hash[key] = [] }
    symmetry_groups.each do |sgroup|
      keys = sgroup['players'].flat_map { |player| player['features'].keys }
      key_map[sgroup['role']] = key_map[sgroup['role']] + keys
    end
    new_player_cvs(key_map).flat_map do |role, names|
      names.map do |name|
        PlayerControlVariable.find_or_create_by(
          name: name, simulator_instance_id: @instance_id, role: role)
      end
    end
  end

  def new_cvs(keys)
    keys - ControlVariable.where(
      simulator_instance_id: @instance_id, name: keys).pluck(:name)
  end


  def new_player_cvs(key_map)
    key_map.each do |key, values|
      uniq_values = values.uniq
      key_map[key] = uniq_values - PlayerControlVariable.where(
        simulator_instance_id: @instance_id, name: values,
        role: key).pluck(:name)
    end
    key_map
  end
end
