#!C:\Python27\python.exe

## Author: Siddarth Srinivasan, UCLA REU 2014
## Date Created: 8th July 2014
## Summary: A support program for robotServer.cgi that allows easy creation,
##          clearing and deletion of databases.

import cgi
import mysql.connector as conn


################################################################################
#                             HTML HANDLERS
################################################################################


def htmlTop():
    """
        Function that generates the html tags till the body.
    """

    print("""Content-type:text/html\n\n
            <!DOCTYPE html>
            <html lang="en">
                <head>
                    <meta charset="utf-8" />
                    <title>
                        Database Manager
                    </title>
                </head>
                <body> """)

def htmlBody():
    """
        Function that generates the body of the page
    """

    print("""<form method = "post" action = "databaseManager.cgi">
                Create Database with Name:
                <input type = "text" name = "dbnamecreate" autofocus = "true"/>
                <br><br>

                Clear Database with Name:
                <input type = "text" name = "dbnameclear" />
                <br><br>

                Delete Database with Name:
                <input type = "text" name = "dbnamedelete" />
                <br><br>

                <input type = "submit" name = "submitall" value = "Submit"/>
            </form>""")

def htmlTail():
    """
        Function that generates the closing html tags
    """

    print("""</body>
        </html>""")

################################################################################
#                             MySQL HANDLERS
################################################################################


def connectDB():
    """
        Function that connects to the database
    """

    db = conn.connect(host = 'localhost', user = 'root', passwd = 'uclaRobots14')
    cursor = db.cursor()
    return db,cursor


def createDB(db, cursor, dbname):
    """
        Function that creates a database with name 'dbname'
    """

    sql = "CREATE DATABASE " + dbname
    cursor.execute(sql)

    sql = "USE " + dbname
    cursor.execute(sql)

    # Create Table that records the states that the Arduino has submitted
    sql = '''CREATE TABLE State_Record
             (StateID int not null auto_increment,
             Timestamp varchar(25) not null,
             State int not null,
             Data int not null,
             currentX int not null,
             currentY int not null,
             theta float not null,
             destX int not null,
             destY int not null,
             Response bool not null,
             Duration int not null,
             Error_Code int not null,
             primary key(StateID))'''
    cursor.execute(sql)

    # Create table that records the data the arduino has collected
    sql = '''CREATE table Data_Collection
             (DataPtID int not null auto_increment,
             startX int not null,
             startY int not null,
             endX int not null,
             endY int not null,
             Data int not null,
             primary key(DataPtID))'''
    cursor.execute(sql)

    db.commit()


def clearDB(db, cursor, dbname, tables):
    """
        Function that clears the database with name 'dbname' of all 'tables'
    """

    sql = "USE " + dbname
    cursor.execute(sql)

    for table in tables:
        sql = "TRUNCATE TABLE " + table
        cursor.execute(sql)

        sql = "DELETE FROM " + table
        cursor.execute(sql)

    db.commit()


def deleteDB(db, cursor, dbname):
    """
        Function that deletes the database with name 'dbname'
    """
    
    sql = "DROP DATABASE " + dbname
    cursor.execute(sql)
    db.commit()


################################################################################
#                             MAIN PROGRAM
################################################################################


if __name__ == "__main__":
    try:
        #print("""Content-type:text/html\n\n""")
        htmlTop()
        htmlBody()

        db,cursor = connectDB()
        tables = ["State_Record", "Data_Collection"]

        formData = cgi.FieldStorage()

        dbNameCreate = formData.getvalue("dbnamecreate")
        dbNameClear  = formData.getvalue("dbnameclear")
        dbNameDelete = formData.getvalue("dbnamedelete")


        if dbNameCreate:
            createDB(db, cursor, dbNameCreate)
        if dbNameClear:
            clearDB(db, cursor, dbNameClear, tables)
        if dbNameDelete:
            deleteDB(db, cursor, dbNameDelete)

        cursor.close()
        
        htmlTail()

    except:
        cgi.print_exception()
