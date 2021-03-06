require 'spec_helper'

describe 'DeviationSchedulers' do
  shared_examples 'a deviation scheduler on requests' do
    before do
      sign_in
    end

    let(:klass) { described_class.to_s }
    let(:scheduler) do
      create(klass.underscore.to_sym)
    end

    context 'POST /schedulers/:id/roles/:role/deviating_strategies',
            type: :feature do
      before do
        scheduler.simulator.add_strategy('All', 'A.B')
        scheduler.add_role('All', scheduler.size)
      end
      it 'should add the strategy to the deviating strategy set' do
        visit "/#{klass.tableize}/#{scheduler.id}"
        click_on 'Add Deviating Strategy'
        expect(page).to have_content('A.B')
        scheduler.reload.roles.first.deviating_strategies
          .should include('A.B')
        scheduler.roles.first.strategies.should_not include('A.B')
      end
    end

    context 'DELETE /schedulers/:id/roles/:role/deviating_strategies',
            type: :feature do
      before do
        scheduler.simulator.add_strategy('All', 'A.B')
        scheduler.add_role('All', scheduler.size)
        scheduler.add_deviating_strategy('All', 'A.B')
      end
      it 'should delete the strategy from the deviating strategy set' do
        visit "/#{klass.tableize}/#{scheduler.id}"
        click_on 'Remove Deviating Strategy'
        scheduler.reload.roles.first.deviating_strategies
          .should_not include('A.B')
      end
    end
  end

  DEVIATION_SCHEDULER_CLASSES.each do |s_class|
    describe s_class do
      it_behaves_like 'a deviation scheduler on requests'
    end
  end
end
