using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InputManager : MonoBehaviour
{
    public Character c;
    public Camera camera;
    // Update is called once per frame
    void Update()
    {
        if (c != null) {
            if (Input.GetMouseButtonDown(1)) {
                RaycastHit hit;
                Ray ray = camera.ScreenPointToRay(Input.mousePosition);
                if (Physics.Raycast(ray, out hit)) {
                    c.SetTarget(hit.point);
                    Debug.Log("Click" + hit.point);
                }
            }
            if (Input.GetKeyDown(KeyCode.Q)) {
                c.PlaySkill(Character.SKILL.ATK1);
            }
            if (Input.GetKeyDown(KeyCode.W)) {
                c.PlaySkill(Character.SKILL.ATK2);
            }
        }
    }
}
