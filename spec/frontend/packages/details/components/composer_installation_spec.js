import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlSprintf, GlLink } from '@gitlab/ui';
import { registryUrl as composerHelpPath } from 'jest/packages/details/mock_data';
import { composerPackage as packageEntity } from 'jest/packages/mock_data';
import ComposerInstallation from '~/packages/details/components/composer_installation.vue';

import { TrackingActions } from '~/packages/details/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ComposerInstallation', () => {
  let wrapper;

  const composerRegistryIncludeStr = 'foo/registry';
  const composerPackageIncludeStr = 'foo/package';

  const store = new Vuex.Store({
    state: {
      packageEntity,
      composerHelpPath,
    },
    getters: {
      composerRegistryInclude: () => composerRegistryIncludeStr,
      composerPackageInclude: () => composerPackageIncludeStr,
    },
  });

  const findRegistryInclude = () => wrapper.find('[data-testid="registry-include"]');
  const findPackageInclude = () => wrapper.find('[data-testid="package-include"]');
  const findHelpText = () => wrapper.find('[data-testid="help-text"]');
  const findHelpLink = () => wrapper.find(GlLink);

  function createComponent() {
    wrapper = shallowMount(ComposerInstallation, {
      localVue,
      store,
      stubs: {
        GlSprintf,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('registry include command', () => {
    it('uses code_instructions', () => {
      const registryIncludeCommand = findRegistryInclude();
      expect(registryIncludeCommand.exists()).toBe(true);
      expect(registryIncludeCommand.props()).toMatchObject({
        instruction: composerRegistryIncludeStr,
        copyText: 'Copy registry include',
        trackingAction: TrackingActions.COPY_COMPOSER_REGISTRY_INCLUDE_COMMAND,
      });
    });

    it('has the correct title', () => {
      expect(findRegistryInclude().props('label')).toBe('composer.json registry include');
    });
  });

  describe('package include command', () => {
    it('uses code_instructions', () => {
      const registryIncludeCommand = findPackageInclude();
      expect(registryIncludeCommand.exists()).toBe(true);
      expect(registryIncludeCommand.props()).toMatchObject({
        instruction: composerPackageIncludeStr,
        copyText: 'Copy require package include',
        trackingAction: TrackingActions.COPY_COMPOSER_PACKAGE_INCLUDE_COMMAND,
      });
    });

    it('has the correct title', () => {
      expect(findPackageInclude().props('label')).toBe('composer.json require package include');
    });

    it('has the correct help text', () => {
      expect(findHelpText().text()).toBe(
        'For more information on Composer packages in GitLab, see the documentation.',
      );
      expect(findHelpLink().attributes()).toMatchObject({
        href: composerHelpPath,
        target: '_blank',
      });
    });
  });
});
