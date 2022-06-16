module MailCtl.CommandLine
  ( Opts(..)
  , Command(..)
  , CronOps(..)
  , optsParser
  )
where

import Data.Version (showVersion)
import Options.Applicative
import Paths_mailctl (version)

data Opts = Opts
  { optConfig  :: !String
  , optCron    :: !Bool
  , optCommand :: !Command
  }
  deriving (Eq, Show)

data Command = Getpwd String | Oauth2 String | Authorize String |
               ListEmails | PrintEnv | Fetch [String] | Cron CronOps
      deriving (Eq, Show)

optsParser :: ParserInfo Opts
optsParser = info
  (helper <*> versionOption <*> programOptions)
  (fullDesc <> progDesc "mailctl is a program to control an msmpt/fdm/mutt email system, using pass as pasword manager, and google OAuth2 method."
  <> header "mailctl - control an msmpt/fdm/mutt email system"
  )

versionOption :: Parser (a -> a)
versionOption = do
  let verinfo = "mailctl version " <> showVersion version
                <> "\nCopyright (C) Peter Dobsan 2022"
  infoOption verinfo (long "version" <> help "Show version")

programOptions :: Parser Opts
programOptions =
  Opts <$> strOption (long "config-file" <> short 'c' <> metavar "CONFIG"
           <> value "/home/peter/.config/mailctl/config.json" <> help "Configuration file")
    <*> switch ( long "run-by-cron" <> help "mailctl invoked by cron" )
    <*> hsubparser (getpwd <> oauth2 <> authorize <> fetch <> cron <> listEmails <> printEnv)

data CronOps = EnableCron | DisableCron | StatusCron 
  deriving (Eq, Show)

cron :: Mod CommandFields Command
cron = command "cron" (info cronOptions (progDesc "Manage running by cron"))
cronOptions :: Parser Command
cronOptions = Cron <$> (statusCron <|> enableCron <|> disableCron)

statusCron :: Parser CronOps
statusCron = flag StatusCron StatusCron ( long "status" <> help "Show cron status." )

enableCron :: Parser CronOps
enableCron = flag' EnableCron ( long "enable" <> help "Enable running by cron." )

disableCron :: Parser CronOps
disableCron = flag' DisableCron ( long "disable" <> help "Disable running by cron." )

fetch :: Mod CommandFields Command
fetch = command "fetch" (info fetchOptions (progDesc "get fdm to fetch all or the given accounts"))
fetchOptions :: Parser Command
fetchOptions = Fetch <$> many (argument str (metavar "EMAIL ..." <> help "Email entries"))

getpwd :: Mod CommandFields Command
getpwd = command "getpwd" (info getPwdOptions (progDesc "get the password of an email entry"))
getPwdOptions :: Parser Command
getPwdOptions = Getpwd <$> strArgument (metavar "EMAIL" <> help "Email entry")

oauth2 :: Mod CommandFields Command
oauth2 = command "oauth2" (info oauth2Options (progDesc "get the oauth2 access code of an email entry"))
oauth2Options :: Parser Command
oauth2Options = Oauth2 <$> strArgument (metavar "EMAIL" <> help "Email entry")

authorize :: Mod CommandFields Command
authorize = command "authorize" (info authorizeOptions (progDesc "authorize an email entry for Oauth2"))
authorizeOptions :: Parser Command
authorizeOptions = Authorize <$> strArgument (metavar "EMAIL" <> help "Email entry")

listEmails :: Mod CommandFields Command
listEmails = command "list" (info (pure ListEmails) (progDesc "list all accounts in fdm's config"))

printEnv :: Mod CommandFields Command
printEnv = command "printenv" (info (pure PrintEnv) (progDesc "Print the current Environment"))
