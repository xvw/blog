--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Data.Function ( (&) )
import           Hakyll



--------------------------------------------------------------------------------


myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
    { feedTitle       = "xvw's blog"
    , feedDescription = "Mon blog qui parle (en général) de code"
    , feedAuthorName  = "Xavier Van de Woestyne"
    , feedAuthorEmail = "xaviervdw@gmail.com"
    , feedRoot        = "https://xvw.github.io"
    }


main :: IO ()
main = hakyll $ do

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "js/*" $ do
        route   idRoute
        compile copyFileCompiler


    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "paintings/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["atom.xml"] $ do
      route idRoute
      compile $ do
        let feedCtx = postCtx `mappend` bodyField "description"
        posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots "posts/*" "content"
        renderAtom myFeedConfiguration feedCtx posts

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            paintings <- recentFirst =<< loadAll "paintings/*"
            let archiveCtx =
                  listField "posts" postCtx (return posts) `mappend`
                  listField "paintings" postCtx (return paintings) `mappend`
                  constField "title" "Archives"            `mappend`
                  defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/front.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    create ["logiciels.html"] $ do
        route idRoute
        compile $ do
            makeItem ""
                >>= loadAndApplyTemplate "templates/logiciels.html" defaultContext
                >>= loadAndApplyTemplate "templates/front.html" defaultContext
                >>= loadAndApplyTemplate "templates/default.html" defaultContext
                >>= relativizeUrls

    create ["peintures.html"] $ do
        route idRoute
        compile $ do
          paintings <-
            (recentFirst =<< loadAll "paintings/*")
          let paintCtx =
                listField "paintings" postCtx (return paintings) `mappend`
                constField "title" "Peintures"             `mappend`
                defaultContext

          makeItem ""
              >>= loadAndApplyTemplate "templates/peintures.html" paintCtx
              >>= loadAndApplyTemplate "templates/front.html" paintCtx
              >>= loadAndApplyTemplate "templates/default.html" paintCtx
              >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <-
              (recentFirst =<< loadAll "posts/*")
            let indexCtx =
                  listField "posts" postCtx (return posts) `mappend`
                  constField "title" "Accueil"             `mappend`
                  defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/front.html" indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%0d du %0m %0Y" `mappend`
    defaultContext
