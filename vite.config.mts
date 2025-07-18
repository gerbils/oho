import { defineConfig } from 'vite'

import inject from '@rollup/plugin-inject';
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    inject({
      $: 'jquery',
      jQuery: 'jquery',
    }),
    RubyPlugin(),
  ],
    build: {
      sourcemap: true,
    },
})
