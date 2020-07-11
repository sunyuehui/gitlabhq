# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigrationJob do
  it_behaves_like 'having unique enum values'

  describe '.for_migration_execution' do
    let!(:job1) { create(:background_migration_job) }
    let!(:job2) { create(:background_migration_job, arguments: ['hi', 2]) }
    let!(:job3) { create(:background_migration_job, class_name: 'OtherJob', arguments: ['hi', 2]) }

    it 'returns jobs matching class_name and arguments' do
      relation = described_class.for_migration_execution('TestJob', ['hi', 2])

      expect(relation.count).to eq(1)
      expect(relation.first).to have_attributes(class_name: 'TestJob', arguments: ['hi', 2])
    end
  end

  describe '.mark_all_as_succeeded' do
    let!(:job1) { create(:background_migration_job, arguments: [1, 100]) }
    let!(:job2) { create(:background_migration_job, arguments: [1, 100]) }
    let!(:job3) { create(:background_migration_job, arguments: [101, 200]) }
    let!(:job4) { create(:background_migration_job, class_name: 'OtherJob', arguments: [1, 100]) }

    it 'marks all matching jobs as succeeded' do
      expect { described_class.mark_all_as_succeeded('TestJob', [1, 100]) }
        .to change { described_class.succeeded.count }.from(0).to(2)

      expect(job1.reload).to be_succeeded
      expect(job2.reload).to be_succeeded
      expect(job3.reload).to be_pending
      expect(job4.reload).to be_pending
    end

    context 'when previous matching jobs have already succeeded' do
      let(:initial_time) { Time.now.round }
      let!(:job1) { create(:background_migration_job, :succeeded, created_at: initial_time, updated_at: initial_time) }

      it 'does not update non-pending jobs' do
        Timecop.freeze(initial_time + 1.day) do
          expect { described_class.mark_all_as_succeeded('TestJob', [1, 100]) }
            .to change { described_class.succeeded.count }.from(1).to(2)
        end

        expect(job1.reload.updated_at).to eq(initial_time)
        expect(job2.reload).to be_succeeded
        expect(job3.reload).to be_pending
        expect(job4.reload).to be_pending
      end
    end
  end
end