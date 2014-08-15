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


def clearDB(db, cursor, dbname, tables):
    """
        Function that clears the database
    """
    cursor.execute("use " + dbname)

    for table in tables:
        sql = "truncate table " + table
        cursor.execute(sql)

        sql = "delete from " + table
        cursor.execute(sql)

    db.commit()


# main program
if __name__ == "__main__":
    try:
        print("""Content-type:text/html\n\n""")

        databaseName = cgi.FieldStorage().getvalue('dbname')
        tables = ["State_Record"]

        if databaseName is None:
            print "Why?"
        else:
            db,cursor = connectDB()
            clearDB(db, cursor, databaseName, tables)
            cursor.close()

            print "Cleared database ", databaseName

        
    except:
        cgi.print_exception()