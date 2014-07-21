#!/usr/local/bin/python2.7

import cgi
import mysql.connector as conn

def connectDB():
    """
        Function that connects to the database
    """

    db = conn.connect(host = 'localhost', user = 'root', passwd = '19*geroniMO')
    cursor = db.cursor()
    return db,cursor


def createDB(db, cursor, dbname):
    """
        Function that creates a database with name 'dbname'
    """

    sql = "create database " + dbname
    cursor.execute(sql)
    db.commit()


def createEntity(db, cursor, dbname):
    """
        Function that creates a table with name 'State_Record'
    """
    sql = "use " + dbname
    cursor.execute(sql)

    sql = '''create table State_Record
             (stateid int not null auto_increment,
             timestamp varchar(25) not null,
             state int not null,
             primary key(stateid))'''
    cursor.execute(sql)
    db.commit()



# main program
if __name__ == "__main__":
    try:
        print("""Content-type:text/html\n\n""")

        databaseName = cgi.FieldStorage().getvalue('dbname')

        if databaseName is None:
            print "Why?"
        else:

            db,cursor = connectDB()
            createDB(db, cursor, databaseName)
            createEntity(db, cursor, databaseName)
            cursor.close()

            print "Created database ", databaseName

        
    except:
        cgi.print_exception()