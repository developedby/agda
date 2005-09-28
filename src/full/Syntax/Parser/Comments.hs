
{-| This module defines the lex action to lex nested comments. As is well-known
    this cannot be done by regular expressions (which, incidently, is probably
    the reason why C-comments don't nest).

    When scanning nested comments we simply keep track of the nesting level,
    counting up for /open comments/ and down for /close comments/.
-}
module Syntax.Parser.Comments
    where

import Syntax.Parser.LexActions
import Syntax.Parser.Monad
import Syntax.Parser.Tokens
import Syntax.Parser.Alex
import Syntax.Parser.LookAhead
import Syntax.Position

import Utils.Monad

-- | Manually lexing a block comment. Assumes an /open comment/ has been lexed.
--   In the end the comment is discarded and 'lexToken' is called to lex a real
--   token.
nestedComment :: LexAction Token
nestedComment inp inp' _ =
    do	setLexInput inp'
	runLookAhead err $ skipBlock "{-" "-}"
	lexToken
    where
        err _ = liftP $ parseErrorAt (lexPos inp) "Unterminated '{-'"

-- | Lex a hole (@{! ... !}@). Holes can be nested.
--   Returns @'TokSymbol' 'SymQuestionMark'@.
hole :: LexAction Token
hole inp inp' _ =
    do	setLexInput inp'
	runLookAhead err $ skipBlock "{!" "!}"
	p <- lexPos <$> getLexInput
	return $ TokSymbol SymQuestionMark (Range (lexPos inp) p)
    where
        err _ = liftP $ parseErrorAt (lexPos inp) "Unterminated '{!'"

-- | Skip a block of text enclosed by the given open and close strings. Assumes
--   the first open string has been consumed. Open-close pairs may be nested.
skipBlock :: String -> String -> LookAhead ()
skipBlock open close = scan 1
    where
	scan 0 = sync
	scan n = match [ open	-->  scan (n + 1)
		       , close	-->  scan (n - 1)
		       ] `other` scan n
	    where
		(-->) = (,)
		other = ($)


