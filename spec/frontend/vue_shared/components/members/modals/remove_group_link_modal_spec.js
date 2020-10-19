import { mount, createLocalVue, createWrapper } from '@vue/test-utils';
import { GlModal, GlForm } from '@gitlab/ui';
import { nextTick } from 'vue';
import { within } from '@testing-library/dom';
import Vuex from 'vuex';
import RemoveGroupLinkModal from '~/vue_shared/components/members/modals/remove_group_link_modal.vue';
import { REMOVE_GROUP_LINK_MODAL_ID } from '~/vue_shared/components/members/constants';
import { group } from '../mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const localVue = createLocalVue();
localVue.use(Vuex);

describe('RemoveGroupLinkModal', () => {
  let wrapper;

  const actions = {
    hideRemoveGroupLinkModal: jest.fn(),
  };

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state: {
        memberPath: '/groups/foo-bar/-/group_links/:id',
        groupLinkToRemove: group,
        removeGroupLinkModalVisible: true,
        ...state,
      },
      actions,
    });
  };

  const createComponent = state => {
    wrapper = mount(RemoveGroupLinkModal, {
      localVue,
      store: createStore(state),
      attrs: {
        static: true,
      },
    });
  };

  const findModal = () => wrapper.find(GlModal);
  const findForm = () => findModal().find(GlForm);
  const getByText = (text, options) =>
    createWrapper(within(findModal().element).getByText(text, options));

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when modal is open', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('sets modal ID', () => {
      expect(findModal().props('modalId')).toBe(REMOVE_GROUP_LINK_MODAL_ID);
    });

    it('displays modal title', () => {
      expect(getByText(`Remove "${group.sharedWithGroup.fullName}"`).exists()).toBe(true);
    });

    it('displays modal body', () => {
      expect(
        getByText(`Are you sure you want to remove "${group.sharedWithGroup.fullName}"?`).exists(),
      ).toBe(true);
    });

    it('displays form with correct action and inputs', () => {
      const form = findForm();

      expect(form.attributes('action')).toBe(`/groups/foo-bar/-/group_links/${group.id}`);
      expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
      expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('submits the form when "Remove group" button is clicked', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      getByText('Remove group').trigger('click');

      expect(submitSpy).toHaveBeenCalled();

      submitSpy.mockRestore();
    });

    it('calls `hideRemoveGroupLinkModal` action when modal is closed', () => {
      getByText('Cancel').trigger('click');

      expect(actions.hideRemoveGroupLinkModal).toHaveBeenCalled();
    });
  });

  it('modal does not show when `removeGroupLinkModalVisible` is `false`', () => {
    createComponent({ removeGroupLinkModalVisible: false });

    expect(findModal().vm.$attrs.visible).toBe(false);
  });
});
