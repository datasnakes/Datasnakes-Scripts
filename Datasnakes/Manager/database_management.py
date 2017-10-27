import os
from pathlib import Path
from importlib import import_module
from Datasnakes.Manager import ProjectManagement
from Datasnakes.Orthologs.utils import attribute_config
from Datasnakes.Tools.ftp import NcbiFTPClient
from Datasnakes.Tools.logit import LogIt
from Datasnakes.Manager.BioSQL import biosql



class DatabaseManagement(object):

    def __init__(self, project, email, project_path=None, proj_mana=ProjectManagement, biosql_mana=biosql, **kwargs):
        self.dbmanalog = LogIt().default(logname="DatabaseManagement", logfile=None)
        self.config_options = {
            "GI_config": self.get_gi_lists,
            "Blast_config": self.download_blast_database,
            "Taxonomy_config": self.download_taxonomy_database,
            "GenBank_config": [self.download_refseq_release_files, self.upload_genbank_flatfiles]
                               }
        self.project = project
        self.email = email
        self.database_dict = {}
        self.ncbiftp = NcbiFTPClient(email=self.email)
        # TODO-ROB:  Configure this differently somehow
        self.biosql = biosql_mana

        # Configuration of class attributes.
        add_self = attribute_config(self, composer=proj_mana, checker=ProjectManagement, project=project, project_path=project_path)
        for var, attr in add_self.__dict__.items():
            setattr(self, var, attr)

        # Determine which database to update
        # And then run that script with the configuration.
        for config in self.config_options.keys():
            if config in kwargs.keys():
                db_config_type = config
                db_config_method = self.config_options[config]
                db_configuration = kwargs[config]
                # db_config_method(kwargs[config])
                self.database_dict[db_config_type] = [db_config_method, db_configuration]

    def get_gi_lists(self):
        print()

    def download_blast_database(self, database_name="refseq_rna", database_path=None):
        # <path>/<user or basic_project>/databases/NCBI/blast/db/<database_name>
        db_path = self.ncbi_db_repo / Path('blast') / Path('db')
        if database_path:
            db_path = Path(database_path)
        self.ncbiftp.getblastdb(database_name=database_name, download_path=db_path)
        # TODO-ROB Add email or slack notifications
        self.dbmanalog.critical("Please set the BLAST environment variables in your .bash_profile!!")
        self.dbmanalog.info("The appropriate environment variable is \'BLASTDB=%s\'." % str(db_path))
        self.dbmanalog.critical("Please set the BLAST environment variables in your .bash_profile!!")
        # TODO-ROB:  set up environment variables.  Also add CLI setup

    def download_taxonomy_database(self, db_type, dest_name=None, dest_path=None, driver=None):
        """
        This method gets the remote data and updates the local databases for ETE3, BioSQL, and PhyloDB taxonomy
        databases.  Most significant is the "biosql" and "phylodb" types.  The biosql databases use NCBI's taxonomy
        database along with the biosql schema.  And the phylodb databases use ITIS's taxonomy database along with the
        biosql schema.

        :param db_type:  The type of database.  ("ete3", "biosq", or "phylodb")
        :param dest_name:  The name of the new database.
        :param dest_path:  The location where the new database should go.
        :param driver:  The type of RDBMS.  ("SQLite", "MySQL", "PostGRE")
        :return:  An updated taxonomy database.
        """
        db_type = str(db_type).lower()
        if db_type == 'ete3':
            # DEFAULT_TAXADB = os.path.join(os.environ.get('HOME', '/'), '.etetoolkit', 'taxa.sqlite')
            ete3 = import_module("ete3")
            ete3.NCBITaxa.update_taxonomy_database()
        elif db_type == 'biosql':
            # Loads data from NCBI via ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy
            if driver.lower() == "sqlite3":
                db_path = self.ncbi_db_repo / Path('pub') / Path('taxonomy')
                ncbi_db = self.biosql.SQLiteBioSQL(database_path=db_path)
                ncbi_db.copy_template_database(dest_name=dest_name, dest_path=dest_path)

            elif driver.lower() == "mysql":
                db_path = self.ncbi_db_repo / Path('pub') / Path('taxonomy')
                ncbi_db = self.biosql.MySQLBioSQL()

        elif db_type == 'phylodb':
            # Loads data from ITIS via http://www.itis.gov/downloads/
            print('biosql_repo')

    # TODO-ROB:  Update ncbiftp class syntax to reflect NCBI's ftp site
    def download_refseq_release_files(self, database_name, database_path, collection_subset, seqtype, format, driver="sqlite3", extension=".gbk.db"):
        db_path = self.ncbi_db_repo / Path('refseq') / Path('release') / Path(collection_subset)
        self.ncbiftp.getrefseqrelease(database_name=collection_subset, seqtype=seqtype, filetype=format, download_path=db_path)
        if database_path:
            db_path = Path(database_path)

    def upload_refseq_release_files(self, database_name, database_path, collection_subset, seqtype, format,
                                    driver="sqlite3", extension=".gbk.db"):
        db_name = str(database_name) + str(extension)
        db_path = self.ncbi_db_repo / Path('refseq') / Path('release') / Path(collection_subset)
        self.download_taxonomy_database(db_type="biosql", dest_name=db_name, dest_path=db_path, driver=driver)
        pass

    def get_project_genbank_database(self):
        print()

