// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  darkMode: 'class',
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant(
      "phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({addVariant}) => addVariant(
      "phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])
    ),
    plugin(({addVariant}) => addVariant(
      "phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])
    ),
    plugin(({addVariant}) => addVariant(
      "phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      const iconsDir = path.join(__dirname, "./vendor/heroicons/optimized")
      const values = {}
      const icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map(file => {
          const name = path.basename(file, ".svg") + suffix
          values[name] = {fullPath: path.join(iconsDir, dir, file), name}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          const content = fs
            .readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "background-color": "currentColor",
            "display": "inline-block",
            "height": theme("spacing.5"),
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "vertical-align": "middle",
            "width": theme("spacing.5")
          }
        }
      }, {values})
    })
  ],
  safelist: [
    // Update the pattern to allow any color and any size
    {
      pattern: /(animate)-([a-zA-Z])/
    },
    {
      pattern: /(bg|border|text|from|to|shadow)-([a-zA-Z]+)-(\d+)/
    },
    {
      pattern: /(dark)/
    }
  ],
  theme: {
    extend: {
      boxShadow: {
        'inner-md': 'inset 0 8px 8px 0 rgb(107 114 128 / 0.5)',
        'inner-sm': 'inset 0 6px 6px 0 rgb(107 114 128 / 0.5)',
        'inner-xs': 'inset 0 4px 4px 0 rgb(107 114 128 / 0.5)',
        'outer-md': '0 0 4px 2px rgb(107 114 128 / 0.5)',
        'outer-sm': '0 0 3px 2px rgb(107 114 128 / 0.5)',
        'outer-xs': '0 0 2px 1px rgb(107 114 128 / 0.5)'
      },
      colors: {
        brand: "#FD4F00"
      },
      fontFamily: {
        'sans': ['Montserrat-Thin', 'Helvetica', 'Arial', 'sans-serif']
      }
    }
  }
}
