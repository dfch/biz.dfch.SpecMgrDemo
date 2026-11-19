import { useTranslation } from 'react-i18next'
import { languages } from '../i18n/i18n'

// The choice of the language (the catalogs EN and DE). The name of each language is in its own language
// (the attribute `lang` of the button), as it is usual for a switch of the language.
export function LanguageSwitcher() {
  const { t, i18n } = useTranslation()
  return (
    <nav aria-label={t('language.label')}>
      {languages.map((language) => (
        <button
          key={language}
          type="button"
          lang={language}
          aria-pressed={i18n.resolvedLanguage === language}
          onClick={() => void i18n.changeLanguage(language)}
        >
          {t(`language.${language}`, { lng: language })}
        </button>
      ))}
    </nav>
  )
}
