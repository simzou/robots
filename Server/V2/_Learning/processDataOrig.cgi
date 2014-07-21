#!/usr/local/bin/python2.7

import cgi
import mysql.connector as conn

def connectDB():
    db = conn.connect(host = 'localhost', user = 'root', passwd = '19*geroniMO')
    cursor = db.cursor()
    return db,cursor

def createDB(db, cursor):
    sql = "create database log0"
    cursor.execute(sql)
    db.commit()

def createEntity(db, cursor):
    sql = "use log0"
    cursor.execute(sql)

    sql = '''create table person
             (personid int not null auto_increment,
             firstname varchar(20) not null,
             lastname varchar(30) not null,
             primary key(personid))'''
    cursor.execute(sql)
    db.commit()

#################################`###############################################
#                             HTML HANDLERS
################################################################################
def htmlTop():
    print("""Content-type:text/html\n\n
            <!DOCTYPE html>
            <html lang="en">
                <head>
                    <meta charset="utf-8" />
                    <title>
                        Robots Server
                    </title>
                </head>
                <body> """)

def htmlBody():
    print("""<form method = "post" action = "processDataOrig.cgi">
                Enter data:
                <input type = "text" name = "state" autofocus = "true"/>
                <input type = "submit" name = "submitdata" value = "Submit" />
            </form>""")

def htmlTail():
    print("""</body>
        </html>""")


def getData():
    formData = cgi.FieldStorage()
    data = formData.getvalue("state")
    return data


# main program

if __name__ == "__main__":
    try:
        #print("""Content-type:text/html\n\n""")
        htmlTop()
        htmlBody()

        db,cursor = connectDB()
        createDB(db, cursor)
        createEntity(db, cursor)
        cursor.close()
        
        g = getData()
        if g is None:
            print "Why?"
        else:
            print(g)
        htmlTail()
    except:
        cgi.print_exception()