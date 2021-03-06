require 'spec_helper'

describe MergeWorker do
  describe "remove source branch" do
    let!(:merge_request) { create(:merge_request, source_branch: "markdown") }
    let!(:source_project) { merge_request.source_project }
    let!(:project) { merge_request.project }
    let!(:author) { merge_request.author }

    before do
      source_project.team << [author, :master]
      source_project.repository.expire_branches_cache
    end

    it 'clears cache of source repo after removing source branch' do
      expect(source_project.repository.branch_names).to include('markdown')

      described_class.new.perform(
        merge_request.id, merge_request.author_id,
        commit_message: 'wow such merge',
        should_remove_source_branch: true)

      merge_request.reload
      expect(merge_request).to be_merged

      source_project.repository.expire_branches_cache
      expect(source_project.repository.branch_names).not_to include('markdown')
    end
  end

  it 'persists merge_jid' do
    merge_request = create(:merge_request, merge_jid: nil)
    user = create(:user)
    worker = described_class.new

    allow(worker).to receive(:jid) { '999' }

    expect { worker.perform(merge_request.id, user.id, {}) }
      .to change { merge_request.reload.merge_jid }.from(nil).to('999')
  end
end
